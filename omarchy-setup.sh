#!/usr/bin/env bash
set -euo pipefail

# Personal overlay for Omarchy (https://omarchy.org).
# Omarchy quattro already ships the coding agents, so this script does not
# install pi, claude, codex, opencode, herdr, docker, git, nvim, gh, fzf,
# fd, ripgrep, jq, zoxide, or chromium.
#
# Checked against basecamp/omarchy@quattro:
#   install/omarchy-base.packages
#   install/user/mise.sh          (pi, claude, codex, opencode, crush, gh, ...)
#   install/user/mise-work.sh     (node via mise)
#   bin/omarchy-default-agent     (pi is a first-class agent)
#   bin/omarchy-theme-set-pi
#
# What this script does add: zsh/omz, bun, rust, java/kotlin, pnpm, turso,
# watchman, cliamp (YouTube Music), bettervim, android studio, yazi, Space Mono,
# bitwarden, ghostty, zed, tailscale, built-in Catppuccin dark, plus personal
# configs and Pi extensions.

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=setup-lib.sh
source "$DOTFILES_DIR/setup-lib.sh"

BETTERVIM_LICENSE=""

usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  --bettervim-license LICENSE  License key for bettervim (only if not already installed)
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

require_omarchy() {
  if [[ -d /usr/share/omarchy ]] || command -v omarchy >/dev/null 2>&1; then
    return
  fi

  echo "This script is for Omarchy. /usr/share/omarchy was not found."
  echo "Use linux-setup.sh on a generic Linux box."
  exit 1
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

activate_omarchy_path() {
  # mise shims put pi/claude/codex/node on PATH for this non-login script.
  export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:${PATH:-}"
  if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate bash)"
  fi
}

bettervim_installed() {
  [[ -d "$HOME/.config/better-vim" ]] ||
    [[ -d "$HOME/.better-vim" ]] ||
    [[ -f "$HOME/.local/state/dotfiles/bettervim.installed" ]]
}

mark_bettervim_installed() {
  mkdir -p "$HOME/.local/state/dotfiles"
  touch "$HOME/.local/state/dotfiles/bettervim.installed"
}

ensure_pi() {
  if have_cmd pi; then
    echo "Pi is already installed (Omarchy ships it via mise)"
    return
  fi

  echo "Pi is missing; installing with mise"
  if command -v mise >/dev/null 2>&1; then
    mise use -g pi
    return
  fi

  echo "mise not found; installing Pi with bun"
  if ! command -v bun >/dev/null 2>&1; then
    curl -fsSL https://bun.sh/install | bash
    export PATH="$HOME/.bun/bin:$PATH"
  fi
  bun add -g @earendil-works/pi-coding-agent
}

install_gap_packages() {
  echo "Installing packages Omarchy does not ship"

  # yazi is not in omarchy-base.packages. ffmpeg/7zip/poppler/resvg are
  # the extras it wants; fd/fzf/ripgrep/zoxide/imagemagick are already there.
  # pac --needed skips packages that are already present.
  pac yazi ffmpeg 7zip poppler resvg

  if have_cmd bitwarden || pacman -Q bitwarden >/dev/null 2>&1; then
    echo "Already installed: bitwarden"
    return 0
  fi

  pac bitwarden
}

install_fonts() {
  echo "Installing Space Mono Nerd Font"

  local fonts_dir="$HOME/.local/share/fonts"
  mkdir -p "$fonts_dir"

  shopt -s nullglob
  local existing=("$fonts_dir"/SpaceMonoNerdFont*.ttf "$fonts_dir"/SpaceMonoNerdFont*.otf)
  shopt -u nullglob
  if ((${#existing[@]} > 0)); then
    echo "Already installed: Space Mono Nerd Font"
    return 0
  fi

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

setup_omarchy_zshrc_local() {
  setup_zshrc_local

  local zshrc_local="$HOME/.zshrc.local"
  if ! grep -q 'mise activate zsh' "$zshrc_local" 2>/dev/null; then
    cat >> "$zshrc_local" <<'EOF'

# Omarchy: mise ships pi, claude, codex, node
command -v mise >/dev/null 2>&1 && eval "$(mise activate zsh)"
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
EOF
  fi
}

install_bun() {
  echo "Installing Bun"

  if have_cmd bun; then
    echo "Already installed: bun"
    return 0
  fi

  if command -v mise >/dev/null 2>&1; then
    mise use -g bun@latest
    return
  fi

  curl -fsSL https://bun.sh/install | bash
  export PATH="$HOME/.bun/bin:$PATH"
}

install_rust() {
  echo "Installing Rust"

  if ! have_cmd rustup; then
    if have_cmd omarchy-install-dev-env; then
      omarchy-install-dev-env rust
    else
      curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | bash -s -- -y
    fi
    # shellcheck disable=SC1091
    [[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"
  fi

  if ! have_cmd rustup; then
    echo "rustup not available after install"
    return 1
  fi

  rustup default stable >/dev/null

  local component
  local -a missing=()
  for component in rustfmt clippy rust-analyzer; do
    if rustup component list --installed 2>/dev/null | grep -q "^${component}"; then
      continue
    fi
    missing+=("$component")
  done

  if ((${#missing[@]} == 0)); then
    echo "Already installed: rust + rustfmt/clippy/rust-analyzer"
    return 0
  fi

  rustup component add "${missing[@]}"
}

install_java_kotlin() {
  echo "Installing Java and Kotlin (via SDKMAN)"

  export SDKMAN_DIR="$HOME/.sdkman"
  if [[ ! -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
    curl -s "https://get.sdkman.io" | bash
  fi

  set +u
  # shellcheck disable=SC1091
  . "$SDKMAN_DIR/bin/sdkman-init.sh"

  if [[ -d "$SDKMAN_DIR/candidates/java/current" ]] || have_cmd java; then
    echo "Already installed: java"
  else
    sdk install java || echo "java install skipped"
  fi

  if [[ -d "$SDKMAN_DIR/candidates/kotlin/current" ]] || have_cmd kotlinc; then
    echo "Already installed: kotlin"
  else
    sdk install kotlin || echo "kotlin install skipped"
  fi

  if [[ -d "$SDKMAN_DIR/candidates/gradle/current" ]] || have_cmd gradle; then
    echo "Already installed: gradle"
  else
    sdk install gradle || echo "gradle install skipped"
  fi
  set -u
}

install_pnpm() {
  echo "Installing pnpm"
  if have_cmd pnpm; then
    echo "Already installed: pnpm"
    return 0
  fi

  curl -fsSL https://get.pnpm.io/install.sh | sh -
}

install_turso() {
  echo "Installing Turso CLI"
  if have_cmd turso; then
    echo "Already installed: turso"
    return 0
  fi

  curl -sSfL https://get.tur.so/install.sh | bash
}

install_cliamp() {
  echo "Installing cliamp"

  if have_cmd cliamp; then
    echo "Already installed: cliamp"
  else
    aur cliamp
  fi

  if have_cmd yt-dlp; then
    echo "Already installed: yt-dlp"
  else
    pac yt-dlp
  fi

  if pacman -Q pipewire >/dev/null 2>&1 && ! pacman -Q pipewire-alsa >/dev/null 2>&1; then
    pac pipewire-alsa
  fi
}

install_watchman() {
  echo "Installing watchman"
  if have_cmd watchman; then
    echo "Already installed: watchman"
    return 0
  fi

  aur watchman-bin
}

install_go() {
  echo "Installing Go"
  if have_cmd go; then
    echo "Already installed: go"
    return 0
  fi

  if command -v mise >/dev/null 2>&1; then
    mise use --global go@latest
    return
  fi

  pac go
}

setup_opam() {
  echo "Configuring OCaml (opam + dune)"

  if ! have_cmd opam; then
    if have_cmd omarchy-install-dev-env; then
      omarchy-install-dev-env ocaml
    else
      echo "opam not found; skipping OCaml setup"
      return 0
    fi
  fi

  if [[ ! -d "$HOME/.opam" ]]; then
    opam init -y --disable-sandboxing || opam init -y
  fi
  eval "$(opam env)"

  if have_cmd dune; then
    echo "Already installed: dune"
    return 0
  fi

  opam install -y dune || echo "dune install failed"
}

install_bettervim() {
  echo "Installing bettervim"

  if bettervim_installed; then
    echo "Already installed: bettervim"
    return 0
  fi

  if [[ -z "$BETTERVIM_LICENSE" ]]; then
    echo "bettervim license is missing. Pass --bettervim-license LICENSE to this script."
    return 1
  fi

  curl -L "https://bettervim.com/install/$BETTERVIM_LICENSE" | bash
  mark_bettervim_installed
}

install_android_studio() {
  echo "Installing Android Studio"
  if have_cmd android-studio; then
    echo "Already installed: android-studio"
  else
    aur android-studio
  fi

  if pacman -Q android-tools >/dev/null 2>&1; then
    echo "Already installed: android-tools"
    return 0
  fi

  pac android-tools
}

install_ghostty() {
  echo "Installing Ghostty"

  if have_cmd ghostty; then
    echo "Already installed: ghostty"
    return 0
  fi

  if command -v omarchy-install-terminal >/dev/null 2>&1; then
    omarchy-install-terminal ghostty
    return
  fi

  pac ghostty
}

install_zed() {
  echo "Installing Zed"

  if have_cmd zed || pacman -Q zed >/dev/null 2>&1; then
    echo "Already installed: zed"
    return 0
  fi

  if command -v omarchy-pkg-add >/dev/null 2>&1; then
    omarchy-pkg-add zed
    return
  fi

  pac zed
}

install_tailscale() {
  echo "Installing Tailscale"

  if have_cmd tailscale; then
    echo "Already installed: tailscale"
  elif have_cmd omarchy-pkg-add; then
    omarchy-pkg-add tailscale
  else
    pac tailscale
  fi

  if systemctl is-enabled --quiet tailscaled.service 2>/dev/null &&
    systemctl is-active --quiet tailscaled.service 2>/dev/null; then
    echo "Already enabled: tailscaled"
    return 0
  fi

  sudo systemctl enable --now tailscaled.service ||
    echo "Could not enable tailscaled.service; enable it manually with: sudo systemctl enable --now tailscaled"
}

set_catppuccin_theme() {
  echo "Setting Omarchy theme to built-in Catppuccin dark"

  if ! have_cmd omarchy-theme-set; then
    echo "omarchy-theme-set not found; skipping theme"
    return 0
  fi

  local current=""
  if [[ -f "$HOME/.local/state/omarchy/current/theme.name" ]]; then
    current="$(<"$HOME/.local/state/omarchy/current/theme.name")"
  fi
  if [[ "$current" == "catppuccin" ]]; then
    echo "Already set: catppuccin"
    return 0
  fi

  if [[ -n "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ]]; then
    omarchy-theme-set catppuccin
  else
    OMARCHY_THEME_HEADLESS=1 omarchy-theme-set catppuccin
  fi
}

print_notes() {
  cat <<'EOF'

------------------------------------------------------------
Skipped on purpose (Omarchy already has these)
------------------------------------------------------------
- pi / oh-my-pi     mise (install/user/mise.sh)
- claude / codex    mise
- opencode / crush  mise
- herdr             omarchy-base.packages
- docker*           omarchy-base.packages
- git / nvim / gh   base + mise
- fd fzf rg jq      omarchy-base.packages
- zoxide / tmux     omarchy-base.packages
- chromium          default browser
- voxtype           dictation (Handy equivalent)
- 1password         not reinstalled; bitwarden is added
- catppuccin        built-in dark; this script applies it

Not installed here:
- Claude / Codex desktop apps
- Helium (use Omarchy's browser picker)
- Handy (use `omarchy-voxtype-install`)

cliamp starts on YouTube Music after setup.
Stay signed into YouTube in Chromium so cookie login works.

Theme is Omarchy's built-in Catppuccin dark.
Light flavor: `omarchy theme set catppuccin-latte`.
After login, run `tailscale up` if you want this machine on the tailnet.
Safe to re-run: already-installed tools and the current theme are skipped.
------------------------------------------------------------
EOF
}

parse_args "$@"

if [[ -z "$BETTERVIM_LICENSE" ]] && ! bettervim_installed; then
  echo "Missing required option: --bettervim-license LICENSE"
  usage
  exit 1
fi

require_omarchy
activate_omarchy_path

echo "Here we go again!"

run_step "gap-packages" install_gap_packages
run_step "fonts" install_fonts
run_step "oh-my-zsh" install_oh_my_zsh
run_step "zshrc-local" setup_omarchy_zshrc_local
run_step "bun" install_bun
run_step "rust" install_rust
run_step "java-kotlin" install_java_kotlin
run_step "pnpm" install_pnpm
run_step "turso" install_turso
run_step "cliamp" install_cliamp
run_step "watchman" install_watchman
run_step "go" install_go
run_step "opam" setup_opam
run_step "bettervim" install_bettervim
run_step "pi" ensure_pi
run_step "pi-config" configure_pi
run_step "codex-config" configure_codex
run_step "claude-config" configure_claude
run_step "ghostty" install_ghostty
run_step "zed" install_zed
run_step "android-studio" install_android_studio
run_step "tailscale" install_tailscale
run_step "zed-config" configure_zed
run_step "herdr-config" configure_herdr
run_step "cliamp-config" configure_cliamp
run_step "catppuccin" set_catppuccin_theme

print_notes
finish_steps
