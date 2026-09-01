#!/usr/bin/env bash
set -euo pipefail

# Thin launcher for the setup scripts in this repo.
# Safe to pipe from curl because it clones (or reuses) the repo first.
#
#   curl -fsSL https://raw.githubusercontent.com/MatheusBBarni/.dotfiles/master/bootstrap.sh \
#     | bash -s -- omarchy --bettervim-license YOUR_LICENSE
#
#   ./bootstrap.sh mac --bettervim-license YOUR_LICENSE

REPO_HTTPS="https://github.com/MatheusBBarni/.dotfiles.git"
REPO_SSH="git@github.com:MatheusBBarni/.dotfiles.git"
CLONE_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
USE_SSH=0

usage() {
  cat <<EOF
Usage: $0 <mac|linux|omarchy|nixos> [setup options]
       $0 [--ssh] [--dir PATH] <mac|linux|omarchy|nixos> [setup options]

Targets:
  mac, macos     macos-setup.sh
  linux          linux-setup.sh
  omarchy        omarchy-setup.sh
  nix, nixos     nixos-setup.sh

Options:
  --dir PATH     Clone / reuse this directory (default: \$DOTFILES_DIR or ~/.dotfiles)
  --ssh          Clone with git@github.com instead of HTTPS
  -h, --help     Show this help

Remaining arguments are passed to the setup script, for example:
  --bettervim-license LICENSE

Curl example:
  curl -fsSL https://raw.githubusercontent.com/MatheusBBarni/.dotfiles/master/bootstrap.sh \\
    | bash -s -- omarchy --bettervim-license YOUR_LICENSE
EOF
}

resolve_local_repo() {
  local here=""
  if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
    here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [[ -f "$here/omarchy-setup.sh" && -f "$here/setup-lib.sh" ]]; then
      printf '%s\n' "$here"
      return 0
    fi
  fi
  return 1
}

ensure_repo() {
  local local_repo=""
  if local_repo="$(resolve_local_repo)"; then
    CLONE_DIR="$local_repo"
    echo "Using local repo: $CLONE_DIR"
    return
  fi

  if [[ -d "$CLONE_DIR/.git" && -f "$CLONE_DIR/omarchy-setup.sh" ]]; then
    echo "Using existing clone: $CLONE_DIR"
    return
  fi

  if [[ -e "$CLONE_DIR" ]]; then
    echo "Refusing to overwrite $CLONE_DIR (not this dotfiles repo)"
    exit 1
  fi

  if ! command -v git >/dev/null 2>&1; then
    echo "git is required to clone $REPO_HTTPS"
    exit 1
  fi

  local repo="$REPO_HTTPS"
  if ((USE_SSH)); then
    repo="$REPO_SSH"
  fi

  echo "Cloning $repo into $CLONE_DIR"
  git clone "$repo" "$CLONE_DIR"
}

script_for_target() {
  case "$1" in
    mac | macos | osx | darwin)
      printf '%s\n' "macos-setup.sh"
      ;;
    linux)
      printf '%s\n' "linux-setup.sh"
      ;;
    omarchy)
      printf '%s\n' "omarchy-setup.sh"
      ;;
    nix | nixos)
      printf '%s\n' "nixos-setup.sh"
      ;;
    *)
      return 1
      ;;
  esac
}

TARGET=""
SETUP_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h | --help)
      usage
      exit 0
      ;;
    --ssh)
      USE_SSH=1
      shift
      ;;
    --dir)
      if [[ $# -lt 2 ]]; then
        echo "--dir requires a path"
        exit 1
      fi
      CLONE_DIR="$2"
      shift 2
      ;;
    --)
      shift
      SETUP_ARGS+=("$@")
      break
      ;;
    -*)
      if [[ -z "$TARGET" ]]; then
        echo "Unknown option: $1"
        usage
        exit 1
      fi
      SETUP_ARGS+=("$1")
      shift
      ;;
    *)
      if [[ -z "$TARGET" ]]; then
        TARGET="$1"
        shift
      else
        SETUP_ARGS+=("$1")
        shift
      fi
      ;;
  esac
done

if [[ -z "$TARGET" ]]; then
  echo "Missing target: mac, linux, omarchy, or nixos"
  usage
  exit 1
fi

SETUP_SCRIPT=""
if ! SETUP_SCRIPT="$(script_for_target "$TARGET")"; then
  echo "Unknown target: $TARGET"
  usage
  exit 1
fi

ensure_repo

if [[ ! -f "$CLONE_DIR/$SETUP_SCRIPT" ]]; then
  echo "Missing $CLONE_DIR/$SETUP_SCRIPT"
  exit 1
fi

echo "Running $SETUP_SCRIPT ${SETUP_ARGS[*]-}"
exec bash "$CLONE_DIR/$SETUP_SCRIPT" "${SETUP_ARGS[@]+"${SETUP_ARGS[@]}"}"
