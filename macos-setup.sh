#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=setup-lib.sh
source "$DOTFILES_DIR/setup-lib.sh"

NODE_VERSION="24"
BETTERVIM_LICENSE=""
SKIP_INSTALLS=()

SKIP_COMPONENTS=(
  bettervim
  bun
  claude
  cliamp
  codex
  fonts
  go
  handy
  herdr
  java
  nvm
  ohmyzsh
  omp
  opencode
  pi
  rust
  apps
  dock
)

skip_component_supported() {
  local component="$1"
  local supported
  for supported in "${SKIP_COMPONENTS[@]}"; do
    if [[ "$supported" == "$component" ]]; then
      return 0
    fi
  done
  return 1
}
DOCK_APPS=(
  "/Applications/Helium.app"
  "/Applications/Zed.app"
  "/Applications/YouTube Music.app"
  "/Applications/Tailscale.app"
  "/Applications/Docker.app"
  "/Applications/Discord.app"
  "/System/Applications/System Settings.app"
)

usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  --bettervim-license LICENSE  Optional license key for bettervim installation
  --skip COMPONENTS           Comma-separated components to skip
                               (rust,go,codex,claude,...)
  -h, --help                  Show this help
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
      --skip)
        if [[ $# -lt 2 ]]; then
          echo "--skip requires a comma-separated component list"
          exit 1
        fi

        local component
        local requested_components
        IFS=',' read -r -a requested_components <<< "$2"
        for component in "${requested_components[@]}"; do
          component="${component//[[:space:]]/}"
          if skip_component_supported "$component"; then
            SKIP_INSTALLS+=("$component")
          else
            echo "Unknown --skip component: $component"
            echo "Supported components: ${SKIP_COMPONENTS[*]}"
            exit 1
          fi
        done
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

skip_requested() {
  local component="$1"
  local requested
  for requested in "${SKIP_INSTALLS[@]}"; do
    if [[ "$requested" == "$component" ]]; then
      return 0
    fi
  done
  return 1
}

run_optional() {
  local component="$1"
  shift
  if skip_requested "$component"; then
    echo "Skipping $component (--skip)"
    return 0
  fi
  "$@"
}

install_brew() {
  if ! command -v brew >/dev/null 2>&1; then
    echo "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  brew update
}

install_base_packages() {
  echo "Installing base packages"
  brew install git mas dockutil
  brew install yazi ffmpeg-full sevenzip jq poppler fd ripgrep fzf zoxide resvg imagemagick-full font-symbols-only-nerd-font
  brew link ffmpeg-full imagemagick-full -f --overwrite
}

configure_dock() {
  echo "Configuring Dock"

  if ! command -v dockutil >/dev/null 2>&1; then
    echo "dockutil not found; skipping Dock setup"
    return
  fi

  dockutil --remove all --no-restart >/dev/null 2>&1 || true

  local app
  for app in "${DOCK_APPS[@]}"; do
    if [[ -d "$app" ]]; then
      dockutil --add "$app" --no-restart
    else
      echo "Dock app not found; skipping: $app"
    fi
  done

  killall Dock >/dev/null 2>&1 || true
}

install_oh_my_zsh() {
  echo "Installing zsh and Oh My Zsh"
  brew install zsh zsh-autosuggestions zsh-syntax-highlighting

  local brew_zsh
  brew_zsh="$(brew --prefix)/bin/zsh"

  if ! grep -qxF "$brew_zsh" /etc/shells; then
    echo "Adding Homebrew zsh to /etc/shells"
    echo "$brew_zsh" | sudo tee -a /etc/shells >/dev/null
  fi

  if [[ "$SHELL" != "$brew_zsh" ]]; then
    echo "Setting Homebrew zsh as the default shell"
    chsh -s "$brew_zsh"
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

  export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
  export PATH="$BUN_INSTALL/bin:$HOME/.local/bin:$PATH"

  if ! command -v bun >/dev/null 2>&1; then
    curl -fsSL https://bun.sh/install | bash
  fi
}

install_herdr() {
  echo "Installing herdr"

  export PATH="$HOME/.local/bin:$PATH"

  if ! command -v herdr >/dev/null 2>&1; then
    curl -fsSL https://herdr.dev/install.sh | sh
  fi
}

install_rust() {
  echo "Installing Rust"

  export CARGO_HOME="${CARGO_HOME:-$HOME/.cargo}"
  export RUSTUP_HOME="${RUSTUP_HOME:-$HOME/.rustup}"
  export PATH="$CARGO_HOME/bin:$PATH"

  if ! command -v rustup >/dev/null 2>&1; then
    brew install rustup-init
    rustup-init -y --no-modify-path
  fi

  if [[ -f "$CARGO_HOME/env" ]]; then
    # shellcheck disable=SC1091
    . "$CARGO_HOME/env"
  fi

  rustup toolchain install stable
  rustup default stable
  rustup component add rustfmt clippy rust-analyzer
}
install_go() {
  echo "Installing Go"
  brew install go gopls
}


install_fonts() {
  echo "Installing fonts"
  brew install --cask font-space-mono-nerd-font
}

install_cliamp() {
  echo "Installing cliamp"
  brew install bjarneo/cliamp/cliamp yt-dlp
}

install_global_bun_packages() {
  echo "Installing global Bun packages"

  if ! command -v bun >/dev/null 2>&1; then
    echo "Bun not found; skipping global packages"
    return 0
  fi

  if skip_requested pi; then
    echo "Skipping pi (--skip)"
  elif command -v pi >/dev/null 2>&1; then
    echo "Already installed: pi"
  else
    bun add -g @earendil-works/pi-coding-agent
  fi

  if skip_requested opencode; then
    echo "Skipping opencode (--skip)"
  elif command -v opencode >/dev/null 2>&1; then
    echo "Already installed: opencode"
  else
    bun add -g opencode-ai
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

install_bettervim() {
  echo "Installing bettervim"

  if bettervim_installed; then
    echo "Already installed: bettervim"
    return 0
  fi

  if [[ -z "$BETTERVIM_LICENSE" ]]; then
    echo "bettervim license not provided; skipping"
    return 0
  fi

  curl -fsSL "https://bettervim.com/install/$BETTERVIM_LICENSE" | bash
  mark_bettervim_installed
}

install_java_kotlin() {
  echo "Installing Java and Kotlin"
  brew install --cask temurin
  brew install kotlin gradle
}

install_handy() {
  echo "Installing Handy"

  if [[ -d "/Applications/Handy.app" ]]; then
    echo "Already installed: Handy"
    return 0
  fi

  local handy_arch
  if [[ "$(uname -m)" == "arm64" ]]; then
    handy_arch="aarch64"
  else
    handy_arch="x64"
  fi

  local handy_url
  handy_url="$(
    curl -fsSL "https://handy.computer/download" |
      perl -ne 'if (/href="([^"]*Handy_[^"]*_'${handy_arch}'\.dmg)"/) { print "$1\n"; exit }'
  )"

  if [[ -z "$handy_url" ]]; then
    handy_url="https://github.com/cjpais/Handy/releases/download/v0.8.1/Handy_0.8.1_${handy_arch}.dmg"
  fi

  local tmp_dmg="/tmp/Handy.dmg"
  curl -fL "$handy_url" -o "$tmp_dmg"

  local mount_point
  mount_point="$(mktemp -d)"

  hdiutil attach "$tmp_dmg" -mountpoint "$mount_point" -nobrowse -quiet

  local app_path
  app_path="$(find "$mount_point" -maxdepth 2 -name "Handy.app" -print -quit)"
  if [[ -z "$app_path" ]]; then
    hdiutil detach "$mount_point" -quiet
    rm -rf "$mount_point" "$tmp_dmg"
    echo "Handy.app was not found in the mounted DMG"
    return 1
  fi

  sudo ditto "$app_path" "/Applications/Handy.app"
  hdiutil detach "$mount_point" -quiet
  rm -rf "$mount_point" "$tmp_dmg"
}
install_apps() {
  echo "Installing apps"
  brew install --cask rectangle raycast bitwarden helium-browser google-chrome zed pear-devs/pear/pear-desktop tailscale docker android-studio android-platform-tools discord ghostty
}

install_xcode() {
  echo "Installing Xcode"

  if [[ ! -d "/Applications/Xcode.app" ]]; then
    if mas account >/dev/null 2>&1; then
      mas install 497799835 || {
        echo "Xcode install failed. Open the App Store, sign in, and install Xcode manually."
        return 0
      }
    else
      echo "Mac App Store is not signed in. Install Xcode manually from the App Store."
      return 0
    fi
  fi

  if [[ -d "/Applications/Xcode.app" ]]; then
    sudo xcode-select -s "/Applications/Xcode.app/Contents/Developer"
    sudo xcodebuild -license accept
    sudo xcodebuild -runFirstLaunch
  fi
}
parse_args "$@"

echo "Here we go again!"

install_brew
install_base_packages
run_optional ohmyzsh install_oh_my_zsh
setup_zshrc_local
run_optional nvm install_nvm
run_optional bun install_bun
run_optional herdr install_herdr
run_optional rust install_rust
run_optional go install_go
run_optional java install_java_kotlin

echo "Installing CLIs"
brew install node pnpm gh neovim watchman jdtls typescript-language-server ocaml opam dune docker docker-compose docker-buildx tursodatabase/tap/turso
run_optional cliamp install_cliamp
run_optional bettervim install_bettervim
run_optional fonts install_fonts
install_global_bun_packages
if skip_requested bun && ! have_cmd omp; then
  echo "Skipping omp because bun was skipped"
else
  run_optional omp install_omp
fi
run_optional codex configure_codex
run_optional pi configure_pi amp-dark
run_optional claude configure_claude
run_optional omp configure_omp

run_optional apps install_apps
configure_zed
run_optional handy install_handy

configure_ghostty
run_optional herdr configure_herdr
run_optional cliamp configure_cliamp
run_optional dock configure_dock

echo "Done"
