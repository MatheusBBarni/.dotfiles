#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE_VERSION="24"
ATLAS_BOOKMARKS_HTML=""

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
  brew install git mas
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

install_gemini_desktop() {
  echo "Installing Gemini desktop app"

  local gemini_url
  gemini_url="$(
    curl -fsSL "https://gemini.google/mac/" |
      perl -ne 'if (/href="(https:\/\/dl\.google\.com\/[^"]+)"/) { print "$1\n"; exit }'
  )"
  gemini_url="${gemini_url:-https://dl.google.com/release2/j33ro/release/Gemini.dmg}"

  local tmp_dmg="/tmp/Gemini.dmg"
  curl -fL "$gemini_url" -o "$tmp_dmg"

  local mount_point
  mount_point="$(mktemp -d)"

  hdiutil attach "$tmp_dmg" -mountpoint "$mount_point" -nobrowse -quiet
  sudo rm -rf "/Applications/Gemini.app"
  sudo ditto "$mount_point/Gemini.app" "/Applications/Gemini.app"
  hdiutil detach "$mount_point" -quiet
  rm -rf "$mount_point" "$tmp_dmg"
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

configure_antigravity() {
  echo "Configuring Antigravity"
  link_file \
    "$DOTFILES_DIR/vscode/vscode-settings.json" \
    "$HOME/Library/Application Support/Antigravity/User/settings.json"

  local antigravity_cli="/Applications/Antigravity.app/Contents/Resources/app/bin/antigravity"
  if [[ ! -x "$antigravity_cli" ]]; then
    antigravity_cli="$(command -v antigravity || true)"
  fi

  if [[ -n "$antigravity_cli" && -x "$antigravity_cli" ]]; then
    EDITOR_CLI="$antigravity_cli" "$DOTFILES_DIR/vscode/vscode-extensions.sh"
  else
    echo "Antigravity CLI not found; skipping extension install"
  fi
}

configure_cmux() {
  echo "Configuring cmux CLI"

  local cmux_bin="/Applications/cmux.app/Contents/Resources/bin/cmux"
  if [[ -x "$cmux_bin" ]]; then
    sudo ln -sf "$cmux_bin" "$(brew --prefix)/bin/cmux"
  fi
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

echo "Installing CLIs"
brew install bun node pnpm gemini-cli neovim watchman compozy/tap/compozy tursodatabase/tap/turso
brew install --cask codex
configure_codex

echo "Installing apps"
brew install --cask rectangle raycast chatgpt-atlas codex-app cmux antigravity zed tailscale android-studio android-platform-tools discord
install_gemini_desktop
install_handy
install_xcode
configure_atlas_extensions
configure_atlas_bookmarks

configure_cmux
configure_antigravity

echo "Done"
