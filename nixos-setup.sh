#!/usr/bin/env bash
set -euo pipefail

# NixOS counterpart of macos-setup.sh.
#
# Requires an already-installed NixOS host. This is not a Nix-on-Ubuntu
# installer and not an Arch script (use linux-setup.sh / omarchy-setup.sh).
#
# System (nixos-rebuild):
#   Hyprland + UWSM session, PipeWire, Docker, Tailscale, zsh, flakes
# User (Home Manager):
#   the macos-setup.sh app list from nixpkgs
# Overlay (this script):
#   oh-my-zsh, bettervim, Helium AppImage, Pi/Codex/Claude configs
#
# macOS analogs:
#   Rectangle -> Hyprland tiling
#   Raycast   -> wofi (Super+D)
#   Dock      -> waybar
#   Homebrew  -> nixpkgs

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=setup-lib.sh
source "$DOTFILES_DIR/setup-lib.sh"

BETTERVIM_LICENSE=""
ENABLE_HYPRLAND=1
REBUILD=1

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64 | amd64)
    HELIUM_ARCH="x86_64"
    NIX_SYSTEM="x86_64-linux"
    ;;
  aarch64 | arm64)
    HELIUM_ARCH="arm64"
    NIX_SYSTEM="aarch64-linux"
    ;;
  *)
    echo "Unsupported CPU architecture: $ARCH"
    exit 1
    ;;
esac

usage() {
  cat <<EOF
Usage: $0 [options]

NixOS bootstrap. Applies Hyprland + workstation modules, installs the
macos-setup.sh app list with Home Manager, then links personal configs.

Options:
  --bettervim-license LICENSE  License key for bettervim (only if not already installed)
  --no-hyprland                Skip the Hyprland compositor module
  --no-rebuild                 Do not write /etc/nixos imports or nixos-rebuild
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
      --no-hyprland)
        ENABLE_HYPRLAND=0
        shift
        ;;
      --no-rebuild)
        REBUILD=0
        shift
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

is_nixos() {
  [[ -e /etc/NIXOS ]] && return 0
  [[ -f /etc/os-release ]] || return 1
  grep -Eq '^ID=nixos$|^ID="nixos"$' /etc/os-release
}

require_nixos() {
  if is_nixos; then
    return
  fi

  echo "This script is for NixOS. /etc/NIXOS was not found."
  echo "Install NixOS first, then re-run."
  echo "macOS: macos-setup.sh   Arch: linux-setup.sh   Omarchy: omarchy-setup.sh"
  exit 1
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

gh_asset_url() {
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" |
    grep -oE '"browser_download_url": *"[^"]+"' |
    sed -E 's/.*"(https[^"]+)".*/\1/' |
    grep -E "$2" |
    head -n1
}

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

write_nixos_dropin() {
  local hyprland_mod="$DOTFILES_DIR/nix/nixos/hyprland.nix"
  local services_mod="$DOTFILES_DIR/nix/nixos/services.nix"
  local dropin="/etc/nixos/dotfiles-imports.nix"
  local user_name="${USER:-$(id -un)}"
  local imports

  imports="    ${services_mod}"
  if ((ENABLE_HYPRLAND)); then
    imports="    ${hyprland_mod}
    ${services_mod}"
  fi

  echo "Writing $dropin"
  sudo tee "$dropin" >/dev/null <<EOF
{ pkgs, ... }:
{
  imports = [
${imports}
  ];

  users.users.${user_name}.extraGroups = [ "docker" "video" "input" ];
  users.users.${user_name}.shell = pkgs.zsh;
}
EOF
}

apply_nixos_system() {
  echo "Applying NixOS system modules"

  if ((REBUILD == 0)); then
    echo "Skipping nixos-rebuild (--no-rebuild)"
    return 0
  fi

  write_nixos_dropin

  if [[ -f /etc/nixos/configuration.nix ]] &&
    ! grep -q 'dotfiles-imports.nix' /etc/nixos/configuration.nix; then
    if grep -q 'hardware-configuration.nix' /etc/nixos/configuration.nix; then
      echo "Inserting ./dotfiles-imports.nix into /etc/nixos/configuration.nix"
      sudo cp /etc/nixos/configuration.nix \
        "/etc/nixos/configuration.nix.bak.dotfiles.$(date +%Y%m%d%H%M%S)"
      sudo sed -i '/hardware-configuration.nix/a\    ./dotfiles-imports.nix' \
        /etc/nixos/configuration.nix
    else
      echo "Add  ./dotfiles-imports.nix  to imports in /etc/nixos/configuration.nix"
    fi
  fi

  if [[ -f /etc/nixos/flake.nix ]] &&
    ! grep -q 'dotfiles-imports.nix' /etc/nixos/flake.nix \
      /etc/nixos/configuration.nix 2>/dev/null; then
    cat <<EOF

This host has /etc/nixos/flake.nix. If the flake does not import
configuration.nix (or the drop-in), add:

  imports = [ ./dotfiles-imports.nix ];

or:

  imports = [
    ${DOTFILES_DIR}/nix/nixos/hyprland.nix
    ${DOTFILES_DIR}/nix/nixos/services.nix
  ];
  users.users.${USER}.extraGroups = [ "docker" "video" "input" ];
EOF
  fi

  echo "Running nixos-rebuild switch"
  sudo nixos-rebuild switch
}

install_home_manager() {
  echo "Applying Home Manager flake (macos-setup app list)"

  export USER="${USER:-$(id -un)}"
  export HOME="${HOME:-$(eval echo "~$USER")}"
  export DOTFILES_IS_NIXOS=1
  if ((ENABLE_HYPRLAND)); then
    export DOTFILES_HYPRLAND=1
  else
    export DOTFILES_HYPRLAND=0
  fi

  local flake="$DOTFILES_DIR/nix#dotfiles-${NIX_SYSTEM}"
  echo "home-manager switch --impure --flake $flake"

  nix --extra-experimental-features "nix-command flakes" run home-manager -- \
    switch --impure --flake "$flake"
}

install_oh_my_zsh() {
  echo "Installing zsh and Oh My Zsh"

  local zsh_path=""
  if have_cmd zsh; then
    zsh_path="$(command -v zsh)"
  elif [[ -x /run/current-system/sw/bin/zsh ]]; then
    zsh_path="/run/current-system/sw/bin/zsh"
  fi

  if [[ -z "$zsh_path" ]]; then
    echo "zsh is not on PATH yet. Re-run after nixos-rebuild, or drop --no-rebuild."
    return 0
  fi

  if ! grep -qxF "$zsh_path" /etc/shells 2>/dev/null; then
    echo "Adding zsh to /etc/shells"
    echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
  fi

  if [[ "${SHELL:-}" != "$zsh_path" ]]; then
    echo "Setting zsh as the default shell"
    chsh -s "$zsh_path" || echo "Could not change default shell; run: chsh -s $zsh_path"
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

setup_nixos_zshrc_local() {
  setup_zshrc_local

  local zshrc_local="$HOME/.zshrc.local"
  if ! grep -q 'hm-session-vars.sh' "$zshrc_local" 2>/dev/null; then
    cat >> "$zshrc_local" <<'EOF'

# Home Manager session vars
if [ -e "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
  . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
elif [ -e "$HOME/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh" ]; then
  . "$HOME/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh"
fi
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
EOF
  fi

  if ! grep -q 'ANDROID_HOME' "$zshrc_local" 2>/dev/null; then
    cat >> "$zshrc_local" <<'EOF'

# Android SDK (Linux)
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"
export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$PATH"
EOF
  fi
}

install_rust_components() {
  echo "Configuring Rust (rustup from nixpkgs)"

  if ! have_cmd rustup; then
    echo "rustup not on PATH yet; skip components until the next login"
    return 0
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

setup_opam() {
  echo "Configuring OCaml (opam + dune)"

  if ! have_cmd opam; then
    echo "opam not found; skipping OCaml setup"
    return 0
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

install_global_bun_packages() {
  echo "Installing global Bun packages"

  if ! have_cmd bun; then
    echo "bun not on PATH yet; skip global packages until the next login"
    return 0
  fi

  bun add -g @earendil-works/pi-coding-agent opencode-ai
}

install_helium() {
  echo "Installing Helium browser"

  if [[ -x "$HOME/Applications/helium.AppImage" ]]; then
    echo "Already installed: Helium AppImage"
    return 0
  fi

  local url
  url="$(gh_asset_url imputnet/helium-linux "${HELIUM_ARCH}\.AppImage$")" || true
  if [[ -z "$url" ]]; then
    echo "Could not resolve a Helium AppImage for $HELIUM_ARCH; skipping"
    return 0
  fi

  install_appimage "Helium" "$url" "helium" "Network;WebBrowser;"
}

print_notes() {
  cat <<'EOF'

------------------------------------------------------------
NixOS notes
------------------------------------------------------------
System (nixos-rebuild):
  Hyprland (UWSM session), PipeWire, Docker, Tailscale, zsh, flakes

User (Home Manager, nixos-unstable):
  git neovim gh yazi fzf fd ripgrep zoxide ffmpeg ghostty zed
  bitwarden discord android-studio handy herdr cliamp turso bun
  nodejs_24 pnpm go rustup jdk21 kotlin gradle watchman ...

Hyprland keys:
  Super+Return     ghostty
  Super+D          wofi (Raycast analog)
  Super+Shift+L    hyprlock
  Super+Shift+S    screenshot

Not installed:
  Helium is an AppImage under ~/Applications
  pear-desktop / Rectangle / Raycast / Dock / Xcode / mas   macOS only
  nvm   nodejs_24 comes from nixpkgs instead

After login:
  exec zsh
  tailscale up
  Log out and pick "Hyprland (UWSM)"
  Stay signed into YouTube in Helium so cliamp cookies work.

NVIDIA: follow https://wiki.hypr.land/Nvidia/ and wiki.nixos.org/wiki/Hyprland
Safe to re-run: completed installs are skipped.
------------------------------------------------------------
EOF
}

parse_args "$@"

if [[ -z "$BETTERVIM_LICENSE" ]] && ! bettervim_installed; then
  echo "Missing required option: --bettervim-license LICENSE"
  usage
  exit 1
fi

require_nixos

echo "Here we go again!"

run_step "nixos-system" apply_nixos_system
run_step "home-manager" install_home_manager
run_step "oh-my-zsh" install_oh_my_zsh
run_step "zshrc-local" setup_nixos_zshrc_local
run_step "rust" install_rust_components
run_step "opam" setup_opam
run_step "bettervim" install_bettervim
run_step "bun-globals" install_global_bun_packages
run_step "pi-config" configure_pi amp-dark
run_step "codex-config" configure_codex
run_step "claude-config" configure_claude
run_step "helium" install_helium
run_step "zed-config" configure_zed
run_step "ghostty-config" configure_ghostty
run_step "herdr-config" configure_herdr
run_step "cliamp-config" configure_cliamp

print_notes
finish_steps
