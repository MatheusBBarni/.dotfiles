#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DIR="$DOTFILES_DIR/zed"
ZED_CONFIG_DIR="${ZED_CONFIG_DIR:-$HOME/.config/zed}"
ZED_DATA_DIR="${ZED_DATA_DIR:-$HOME/Library/Application Support/Zed}"

mkdir -p "$TARGET_DIR"

copy_file() {
  local name="$1"
  local source="$ZED_CONFIG_DIR/$name"
  local target="$TARGET_DIR/$name"

  if [[ -f "$source" ]]; then
    cp "$source" "$target"
    echo "Exported $name"
  else
    echo "Skipping $name; not found at $source"
  fi
}

copy_dir() {
  local name="$1"
  local source="$ZED_CONFIG_DIR/$name"
  local target="$TARGET_DIR/$name"

  if [[ -d "$source" ]]; then
    rm -rf "$target"
    cp -R "$source" "$target"
    echo "Exported $name/"
  else
    echo "Skipping $name/; not found at $source"
  fi
}

copy_file settings.json
copy_file keymap.json
copy_file tasks.json
copy_file debug.json
copy_dir snippets
copy_dir themes

extensions_dir="$ZED_DATA_DIR/extensions/installed"
extensions_target="$TARGET_DIR/auto-install-extensions.json"

if [[ -d "$extensions_dir" ]]; then
  {
    echo "{"
    echo '  "auto_install_extensions": {'

    first=1
    while IFS= read -r extension; do
      [[ -n "$extension" ]] || continue
      extension="${extension//\\/\\\\}"
      extension="${extension//\"/\\\"}"

      if [[ "$first" -eq 1 ]]; then
        first=0
      else
        printf ',\n'
      fi

      printf '    "%s": true' "$extension"
    done < <(find "$extensions_dir" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort)

    printf '\n'
    echo "  }"
    echo "}"
  } >"$extensions_target"

  echo "Exported extension names to auto-install-extensions.json"
  echo "Merge that object into zed/settings.json so Zed installs them on new machines."
else
  echo "Skipping extensions; not found at $extensions_dir"
fi
