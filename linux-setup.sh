#!/usr/bin/env bash
set -euo pipefail

# Linux counterpart of macos-setup.sh, targeting Omarchy (an Arch Linux based
# distro). Uses pacman for official packages and yay for the AUR (Omarchy ships
# yay). Mirrors the macOS script: helpers, modular install_/configure_
# functions, and an ordered invocation section at the bottom.
#
# Omarchy already provides a tiling window manager (so no Rectangle) and an app
# launcher (so no Raycast). Apps with no Linux build are noted in print_notes.

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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

backup_path() {
  local path="$1"
  if [[ -e "$path" || -L "$path" ]]; then
    mv "$path" "${path}.backup.$(date +%Y%m%d%H%M%S)"
  fi
}

link_file() {
  local source="$1"
  local target="$2"

  mkdir -p "$(dirname "$target")"

  if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
    return
  fi

  backup_path "$target"
  ln -s "$source" "$target"
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
    neovim go github-cli opam android-tools
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

setup_zshrc_local() {
  echo "Setting up .zshrc.local for local API keys"

  local zshrc_local="$HOME/.zshrc.local"
  if [[ ! -f "$zshrc_local" ]]; then
    cat > "$zshrc_local" <<'EOF'
# Local environment variables (not committed to git)
# Add your API keys and local configs here

export OPENCODE_API_KEY="sk-YOUR_KEY_HERE"
export ZAI_API_KEY="YOUR_KEY_HERE"
EOF
    chmod 600 "$zshrc_local"
  fi
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

install_claude() {
  echo "Installing Claude Code"

  if ! command -v claude >/dev/null 2>&1; then
    curl -fsSL https://claude.ai/install.sh | bash
  else
    echo "Claude Code is already installed"
  fi
}

install_codex_app() {
  echo "Codex desktop app is not available for Linux"
  echo "The Codex CLI is installed instead via @openai/codex"
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
  bun add -g @earendil-works/pi-coding-agent opencode-ai @openai/codex
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

configure_codex() {
  echo "Configuring Codex"

  if command -v codex >/dev/null 2>&1; then
    if ! codex mcp list 2>/dev/null | awk '{print $1}' | grep -qx "context7"; then
      codex mcp add context7 -- npx -y @upstash/context7-mcp
    fi
  else
    echo "Codex CLI not found; skipping Context7 MCP setup"
  fi

  mkdir -p "$HOME/.codex/agents"
  for agent in "$DOTFILES_DIR"/ai/agents/codex/*.toml; do
    link_file "$agent" "$HOME/.codex/agents/$(basename "$agent")"
  done

  mkdir -p "$HOME/.codex/skills"
  for skill in "$DOTFILES_DIR"/ai/skills/*; do
    [[ -d "$skill" ]] || continue
    link_file "$skill" "$HOME/.codex/skills/$(basename "$skill")"
  done
}

configure_pi() {
  echo "Configuring Pi"

  if ! command -v pi >/dev/null 2>&1; then
    echo "Pi CLI not found; skipping Pi extension setup"
    return
  fi

  pi install npm:amp-themes
  pi install npm:pi-subagents
  pi install npm:@matheusbbarni/pi-goal-extension
  pi install npm:@matheusbbarni/pi-message-queue
  pi install npm:@matheusbbarni/pi-stitch-mcp

  local settings_file="$HOME/.pi/agent/settings.json"
  mkdir -p "$HOME/.pi/agent"

  local -a required_packages=(
    "npm:amp-themes"
    "npm:pi-subagents"
    "npm:@matheusbbarni/pi-goal-extension"
    "npm:@matheusbbarni/pi-message-queue"
    "npm:@matheusbbarni/pi-stitch-mcp"
  )

  if command -v python3 >/dev/null 2>&1; then
    python3 - "$settings_file" "${required_packages[@]}" <<'PY'
import json
import os
import sys

settings_path = sys.argv[1]
required_packages = sys.argv[2:]
theme = "amp-dark"

current = {}
if os.path.exists(settings_path):
    try:
        with open(settings_path, "r", encoding="utf-8") as f:
            content = f.read().strip()
            if content:
                current = json.loads(content)
    except Exception:
        current = {}

packages = current.get("packages", [])
if not isinstance(packages, list):
    packages = []

for package in required_packages:
    if package not in packages:
        packages.append(package)

current["packages"] = packages
current["theme"] = theme

os.makedirs(os.path.dirname(settings_path), exist_ok=True)
with open(settings_path, "w", encoding="utf-8") as f:
    json.dump(current, f, indent=2)
    f.write("\n")
PY
  else
    echo "python3 not found; skipping Pi settings.json update"
  fi

  mkdir -p "$HOME/.pi/agent/agents"
  for agent in "$DOTFILES_DIR"/ai/agents/pi/*.md; do
    [[ -f "$agent" ]] || continue
    link_file "$agent" "$HOME/.pi/agent/agents/$(basename "$agent")"
  done

  mkdir -p "$HOME/.pi/agent/extensions"
  for extension in "$DOTFILES_DIR"/ai/extensions/pi/*.{ts,js}; do
    [[ -f "$extension" ]] || continue
    link_file "$extension" "$HOME/.pi/agent/extensions/$(basename "$extension")"
  done

  mkdir -p "$HOME/.pi/agent/skills"
  for skill in "$DOTFILES_DIR"/ai/skills/*; do
    [[ -d "$skill" ]] || continue
    link_file "$skill" "$HOME/.pi/agent/skills/$(basename "$skill")"
  done
}

configure_claude() {
  echo "Configuring Claude Code"

  mkdir -p "$HOME/.claude"

  if [[ -f "$DOTFILES_DIR/ai/claude/CLAUDE.md" ]]; then
    link_file "$DOTFILES_DIR/ai/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
  fi

  mkdir -p "$HOME/.claude/skills"
  for skill in "$DOTFILES_DIR"/ai/skills/*; do
    [[ -d "$skill" ]] || continue
    link_file "$skill" "$HOME/.claude/skills/$(basename "$skill")"
  done
}

configure_zed() {
  echo "Configuring Zed"

  local zed_config_dir="$HOME/.config/zed"
  local config_files=(settings.json keymap.json tasks.json debug.json)
  local config_dirs=(snippets themes)
  local item

  mkdir -p "$zed_config_dir"

  for item in "${config_files[@]}"; do
    if [[ -f "$DOTFILES_DIR/zed/$item" ]]; then
      link_file "$DOTFILES_DIR/zed/$item" "$zed_config_dir/$item"
    fi
  done

  for item in "${config_dirs[@]}"; do
    if [[ -d "$DOTFILES_DIR/zed/$item" ]]; then
      link_file "$DOTFILES_DIR/zed/$item" "$zed_config_dir/$item"
    fi
  done

  if [[ -f "$DOTFILES_DIR/zed/auto-install-extensions.json" ]]; then
    echo "Zed extensions are exported in zed/auto-install-extensions.json"
    echo "Merge them into zed/settings.json under auto_install_extensions."
  fi
}

configure_ghostty() {
  echo "Configuring Ghostty"

  if [[ -f "$DOTFILES_DIR/ghostty/config" ]]; then
    link_file "$DOTFILES_DIR/ghostty/config" "$HOME/.config/ghostty/config"
  fi
}

print_notes() {
  cat <<'EOF'

------------------------------------------------------------
Omarchy notes (differences from the macOS setup)
------------------------------------------------------------
- Rectangle       Not installed. Omarchy ships a tiling window manager.
- Raycast         Not installed, per request. Use Omarchy's launcher.
- ChatGPT Atlas   Replaced by Helium (installed as an AppImage under
                  ~/Applications; the AUR package helium-browser-bin is an
                  alternative if you prefer pacman/yay management).
- cmux            Removed, per request. The Ghostty config is still linked.
- Handy           Installed from the AUR (handy-bin).
- Xcode / mas     macOS only. No Linux equivalent.
- dockutil / Dock macOS only. No Linux equivalent.

Verify before relying on them (may be macOS only):
- codex-app (GUI) Not available for Linux yet; sign up for availability updates
                  at https://openai.com/form/codex-app/. The Codex CLI is
                  installed via npm.
- pear-desktop    Availability unclear. Check https://pears.com for a Linux build.
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
install_watchman
setup_opam
install_docker

install_bettervim
install_claude
install_codex_app

install_global_bun_packages
configure_codex
configure_pi
configure_claude

echo "Installing apps"
install_desktop_apps
install_android_studio
install_handy
install_helium
install_tailscale

configure_zed
configure_ghostty

print_notes

echo "Done"
