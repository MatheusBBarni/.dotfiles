#!/usr/bin/env bash
set -euo pipefail

# Generic Arch/Linux counterpart of macos-setup.sh.
# On Omarchy, prefer omarchy-setup.sh - that script skips packages and agents
# the distro already ships (pi, claude, codex, opencode, herdr, docker, ...).
#
# Uses pacman for official packages and yay for the AUR.

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=setup-lib.sh
source "$DOTFILES_DIR/setup-lib.sh"

NODE_VERSION="24"
BETTERVIM_LICENSE=""

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64 | amd64) HELIUM_ARCH="x86_64" ;;
  aarch64 | arm64) HELIUM_ARCH="arm64" ;;
  *)
    echo "Unsupported CPU architecture: $ARCH"
    exit 1
    ;;
esac

usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  --bettervim-license LICENSE  License key for bettervim installation (required)
  -h, --help                   Show this help
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --bettervim-license)
        if [[ $# -lt 2 ]]; then
          echo "--bettervim-license requires a license value"
          exit 1
        fi
        BETTERVIM_LICENSE="$2"
        shift 2
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      *)
        echo "Unknown option: $1"
        usage
        exit 1
        ;;
    esac
  done
}

# Return the first release asset download URL matching a regex.
# Usage: gh_asset_url <owner/repo> <grep-extended-regex>
gh_asset_url() {
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" |
    grep -oE '"browser_download_url": *"[^"]+"' |
    sed -E 's/.*"(https[^"]+)".*/\1/' |
    grep -E "$2" |
    head -n1
}

pac() {
  sudo pacman -S --needed --noconfirm "$@"
}

ensure_yay() {
  if command -v yay >/dev/null 2>&1; then
    return
  fi

  echo "Bootstrapping yay (AUR helper)"
  sudo pacman -S --needed --noconfirm git base-devel

  local tmp
  tmp="$(mktemp -d)"
  git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
  (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
  rm -rf "$tmp"
}

aur() {
  ensure_yay
  yay -S --needed --noconfirm "$@"
}

# Download an AppImage and register a desktop entry for it.
# Usage: install_appimage <display name> <url> <basename> [categories]
install_appimage() {
  local name="$1" url="$2" base="$3" categories="${4:-Utility;}"
  local apps_dir="$HOME/Applications"
  local target="$apps_dir/${base}.AppImage"
  local desktop="$HOME/.local/share/applications/${base}.desktop"

  mkdir -p "$apps_dir" "$(dirname "$desktop")"
  curl -fL "$url" -o "$target"
  chmod +x "$target"

  cat > "$desktop" <<EOF
[Desktop Entry]
Name=$name
Exec=$target %U
Type=Application
Categories=$categories
Terminal=false
EOF
}

install_base_packages() {
  echo "Installing base packages"

  sudo pacman -Syu --noconfirm
  pac base-devel git curl wget file gnupg unzip zip openssl pkgconf fuse2 \
    zsh jq ripgrep fzf fd ffmpeg 7zip poppler imagemagick zoxide yazi resvg \
    neovim go gopls jdtls typescript-language-server github-cli opam android-tools
}

install_fonts() {
  echo "Installing fonts (Space Mono + Symbols Only Nerd Font)"

  pac ttf-nerd-fonts-symbols

  # Space Mono Nerd Font is not in the official repos; pull it from upstream.
  local fonts_dir="$HOME/.local/share/fonts"
  mkdir -p "$fonts_dir"

  local tmp
  tmp="$(mktemp -d)"
  if curl -fL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/SpaceMono.zip" -o "$tmp/font.zip"; then
    unzip -q -o "$tmp/font.zip" -d "$fonts_dir" -x "*.md" "LICENSE*" || true
  else
    echo "Could not download SpaceMono Nerd Font; skipping"
  fi
  rm -rf "$tmp"

  if command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f "$fonts_dir" >/dev/null 2>&1 || true
  fi
}

install_oh_my_zsh() {
  echo "Installing zsh and Oh My Zsh"

  pac zsh

  local zsh_path
  zsh_path="$(command -v zsh)"

  if [[ -n "$zsh_path" ]] && ! grep -qxF "$zsh_path" /etc/shells; then
    echo "Adding zsh to /etc/shells"
    echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
  fi

  if [[ "${SHELL:-}" != "$zsh_path" ]]; then
    echo "Setting zsh as the default shell"
    chsh -s "$zsh_path" || echo "Could not change default shell automatically; run: chsh -s $zsh_path"
  fi

  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
      "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi

  local custom_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  mkdir -p "$custom_dir/plugins"

  if [[ ! -d "$custom_dir/plugins/zsh-autosuggestions" ]]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions \
      "$custom_dir/plugins/zsh-autosuggestions"
  fi

  if [[ ! -d "$custom_dir/plugins/zsh-syntax-highlighting" ]]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
      "$custom_dir/plugins/zsh-syntax-highlighting"
  fi

  link_file "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
}

install_nvm() {
  echo "Installing nvm"

  if [[ ! -s "$HOME/.nvm/nvm.sh" ]]; then
    PROFILE=/dev/null bash -c \
      "$(curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh)"
  fi

  export NVM_DIR="$HOME/.nvm"
  # shellcheck disable=SC1091
  . "$NVM_DIR/nvm.sh"

  nvm install "$NODE_VERSION"
  nvm alias default "$NODE_VERSION"
  nvm use default
}

install_bun() {
  echo "Installing Bun"

  if ! command -v bun >/dev/null 2>&1; then
    curl -fsSL https://bun.sh/install | bash
  fi
  export PATH="$HOME/.bun/bin:$PATH"
}

install_herdr() {
  echo "Installing herdr"

  if ! command -v herdr >/dev/null 2>&1; then
    curl -fsSL https://herdr.dev/install.sh | sh
  fi
}

install_rust() {
  echo "Installing Rust"

  pac rustup
  export PATH="$HOME/.cargo/bin:$PATH"

  rustup default stable
  rustup component add rustfmt clippy rust-analyzer
}

install_java_kotlin() {
  echo "Installing Java and Kotlin (via SDKMAN)"

  export SDKMAN_DIR="$HOME/.sdkman"
  if [[ ! -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
    curl -s "https://get.sdkman.io" | bash
  fi

  # SDKMAN's init script references unset vars; relax nounset around it.
  set +u
  # shellcheck disable=SC1091
  . "$SDKMAN_DIR/bin/sdkman-init.sh"
  sdk install java || echo "java install skipped"
  sdk install kotlin || echo "kotlin install skipped"
  sdk install gradle || echo "gradle install skipped"
  set -u
}

install_pnpm() {
  echo "Installing pnpm"
  if ! command -v pnpm >/dev/null 2>&1; then
    curl -fsSL https://get.pnpm.io/install.sh | sh -
  fi
}

install_turso() {
  echo "Installing Turso CLI"
  if ! command -v turso >/dev/null 2>&1; then
    curl -sSfL https://get.tur.so/install.sh | bash
  fi
}

install_cliamp() {
  echo "Installing cliamp"

  if ! command -v cliamp >/dev/null 2>&1; then
    aur cliamp
  fi

  pac yt-dlp

  if pacman -Q pipewire >/dev/null 2>&1; then
    pac pipewire-alsa
  fi
}

install_watchman() {
  echo "Installing watchman"
  if ! command -v watchman >/dev/null 2>&1; then
    aur watchman-bin
  fi
}

setup_opam() {
  echo "Configuring OCaml (opam + dune)"

  if ! command -v opam >/dev/null 2>&1; then
    echo "opam not found; skipping OCaml setup"
    return
  fi

  if [[ ! -d "$HOME/.opam" ]]; then
    opam init -y --disable-sandboxing || opam init -y
  fi
  eval "$(opam env)"
  opam install -y dune || echo "dune install failed"
}

install_docker() {
  echo "Installing Docker Engine"

  pac docker docker-compose docker-buildx

  sudo systemctl enable --now docker.service ||
    echo "Could not enable docker.service; enable it manually with: sudo systemctl enable --now docker"

  if ! getent group docker >/dev/null 2>&1; then
    sudo groupadd docker || true
  fi
  sudo usermod -aG docker "$USER" || true
  echo "Added $USER to the docker group. Log out and back in for it to take effect."
}

install_bettervim() {
  echo "Installing bettervim"

  if [[ -z "$BETTERVIM_LICENSE" ]]; then
    echo "bettervim license is missing. Pass --bettervim-license LICENSE to this script."
    exit 1
  fi

  curl -L "https://bettervim.com/install/$BETTERVIM_LICENSE" | bash
}

install_global_bun_packages() {
  echo "Installing global Bun packages"

  export PATH="$HOME/.bun/bin:$PATH"
  bun add -g @earendil-works/pi-coding-agent opencode-ai
}

install_desktop_apps() {
  echo "Installing desktop apps"
  # Ghostty per request: pacman -S ghostty. Zed, Bitwarden and Discord are all
  # in the official repos too.
  pac ghostty zed bitwarden discord
}

install_android_studio() {
  echo "Installing Android Studio"
  if ! command -v android-studio >/dev/null 2>&1; then
    aur android-studio
  fi
}

install_handy() {
  echo "Installing Handy"
  aur handy-bin
}

install_helium() {
  echo "Installing Helium browser"

  local url
  url="$(gh_asset_url imputnet/helium-linux "${HELIUM_ARCH}\.AppImage$")" || true
  if [[ -z "$url" ]]; then
    echo "Could not resolve a Helium AppImage for $HELIUM_ARCH; skipping"
    return
  fi

  install_appimage "Helium" "$url" "helium" "Network;WebBrowser;"
}

install_tailscale() {
  echo "Installing Tailscale"

  pac tailscale
  sudo systemctl enable --now tailscaled.service ||
    echo "Could not enable tailscaled.service; enable it manually with: sudo systemctl enable --now tailscaled"
}

print_notes() {
  cat <<'EOF'

------------------------------------------------------------
Linux notes
------------------------------------------------------------
On Omarchy, use omarchy-setup.sh instead of this script.
It skips agents and packages the distro already ships.

- Rectangle / Raycast / Dock   macOS only
- ChatGPT Atlas                Helium AppImage under ~/Applications
- Handy                        AUR handy-bin
- cliamp                       AUR; YouTube Music uses yt-dlp + browser cookies
- Claude / Codex desktop       not installed
- pear-desktop                 check https://pears.com for a Linux build
------------------------------------------------------------
EOF
}

parse_args "$@"

if [[ -z "$BETTERVIM_LICENSE" ]]; then
  echo "Missing required option: --bettervim-license LICENSE"
  usage
  exit 1
fi

echo "Here we go again!"

install_base_packages
install_fonts
install_oh_my_zsh
setup_zshrc_local
install_nvm
install_bun
install_herdr
install_rust
install_java_kotlin

echo "Installing CLIs"
install_pnpm
install_turso
install_cliamp
install_watchman
setup_opam
install_docker

install_bettervim

install_global_bun_packages
install_omp
configure_codex
configure_pi amp-dark
configure_claude
configure_omp

echo "Installing apps"
install_desktop_apps
install_android_studio
install_handy
install_helium
install_tailscale

configure_zed
configure_ghostty
configure_herdr
configure_cliamp

print_notes

echo "Done"
