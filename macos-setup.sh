#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE_VERSION="24"
ATLAS_BOOKMARKS_HTML=""
DOCK_APPS=(
  "/Applications/ChatGPT Atlas.app"
  "/Applications/cmux.app"
  "/Applications/Zed.app"
  "/Applications/Codex.app"
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
  --atlas-bookmarks-html PATH  Local Brave/Chrome bookmarks HTML export to import into Atlas
  -h, --help                   Show this help
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --atlas-bookmarks-html)
        if [[ $# -lt 2 ]]; then
          echo "--atlas-bookmarks-html requires a file path"
          exit 1
        fi
        ATLAS_BOOKMARKS_HTML="$2"
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

  if ! command -v bun >/dev/null 2>&1; then
    curl -fsSL https://bun.sh/install | bash
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

install_java_kotlin() {
  echo "Installing Java and Kotlin"

  brew install --cask temurin
  brew install kotlin gradle
}

install_handy() {
  echo "Installing Handy"

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

  sudo rm -rf "/Applications/Handy.app"
  sudo ditto "$app_path" "/Applications/Handy.app"
  hdiutil detach "$mount_point" -quiet
  rm -rf "$mount_point" "$tmp_dmg"
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

configure_atlas_extensions() {
  echo "Opening Atlas extension install pages"

  local atlas_app="/Applications/ChatGPT Atlas.app"
  if [[ ! -d "$atlas_app" ]]; then
    echo "ChatGPT Atlas is not installed; skipping extension pages"
    return
  fi

  local extension_urls=(
    "https://chromewebstore.google.com/detail/bitwarden-password-manager/nngceckbapebfimnlniiiahkandclblb"
    "https://chromewebstore.google.com/detail/react-developer-tools/fmkadmapgofadopljbjfkapdkoienihi"
    "https://chromewebstore.google.com/detail/volume-master/jghecgabfgfdldnmbfkhmffcabddioke"
    "https://chromewebstore.google.com/detail/cuponomia-cupom-e-cashbac/gidejehfgombmkfflghejpncblgfkagj"
  )

  for extension_url in "${extension_urls[@]}"; do
    open -a "ChatGPT Atlas" "$extension_url"
  done
}

configure_atlas_bookmarks() {
  if [[ -z "$ATLAS_BOOKMARKS_HTML" ]]; then
    return
  fi

  echo "Preparing Atlas bookmarks import"

  local bookmarks_file
  bookmarks_file="$(cd "$(dirname "$ATLAS_BOOKMARKS_HTML")" && pwd)/$(basename "$ATLAS_BOOKMARKS_HTML")"

  if [[ ! -f "$bookmarks_file" ]]; then
    echo "Bookmarks file not found: $bookmarks_file"
    exit 1
  fi

  case "$bookmarks_file" in
    "$DOTFILES_DIR"/*)
      echo "Warning: bookmarks file is inside this repo. Keep it untracked."
      ;;
  esac

  local atlas_app="/Applications/ChatGPT Atlas.app"
  if [[ ! -d "$atlas_app" ]]; then
    echo "ChatGPT Atlas is not installed; skipping bookmarks import"
    return
  fi

  if command -v pbcopy >/dev/null 2>&1; then
    printf "%s" "$bookmarks_file" | pbcopy
  fi

  open -a "ChatGPT Atlas" "chrome://bookmarks/"
  open -R "$bookmarks_file"

  echo "Atlas does not expose a reliable bookmarks import CLI."
  echo "In Atlas, open Bookmarks Manager > menu > Import bookmarks, then select:"
  echo "$bookmarks_file"
}

configure_cmux() {
  echo "Configuring cmux"

  if [[ -f "$DOTFILES_DIR/cmux/settings.json" ]]; then
    link_file "$DOTFILES_DIR/cmux/settings.json" "$HOME/.config/cmux/settings.json"
  fi

  if [[ -f "$DOTFILES_DIR/cmux/ghostty/config" ]]; then
    link_file "$DOTFILES_DIR/cmux/ghostty/config" "$HOME/.config/ghostty/config"
  fi
}

configure_pi() {
  echo "Configuring Pi"

  if ! command -v pi >/dev/null 2>&1; then
    echo "Pi CLI not found; skipping Pi extension setup"
    return
  fi

  pi install npm:pi-subagents

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

parse_args "$@"

echo "Here we go again!"

install_brew
install_base_packages
install_oh_my_zsh
install_nvm
install_bun
install_rust
install_java_kotlin

echo "Installing CLIs"
brew install node pnpm gh neovim watchman go ocaml opam dune docker docker-compose docker-buildx tursodatabase/tap/turso

echo "Installing global Bun packages"
bun add -g @earendil-works/pi-coding-agent opencode-ai
brew install --cask codex
configure_codex
configure_pi

echo "Installing apps"
brew install --cask rectangle raycast bitwarden chatgpt-atlas codex-app cmux zed pear-devs/pear/pear-desktop tailscale docker android-studio android-platform-tools discord
configure_zed
install_handy
configure_atlas_extensions
configure_atlas_bookmarks

configure_cmux
configure_dock

echo "Done"
