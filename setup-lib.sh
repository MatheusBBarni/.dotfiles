#!/usr/bin/env bash
# Shared helpers for macos-setup.sh, linux-setup.sh, omarchy-setup.sh, and nixos-setup.sh.
# Callers must set DOTFILES_DIR before sourcing this file.

# Third-party packages plus the ones published from pi-extensions / pi-supergrok-usage.
# Local unpublished files still live in ai/extensions/pi/ and are linked below.
PI_PACKAGES=(
  "npm:amp-themes"
  "npm:awesome-pi-themes"
  "npm:pi-subagents"
  "npm:pi-mcp-adapter"
  "npm:@ff-labs/pi-fff"
  "npm:@narumitw/pi-goal"
  "npm:pi-zentui"
  "npm:@juicesharp/rpiv-ask-user-question"
  "npm:@matheusbbarni/pi-message-queue"
  "npm:@matheusbbarni/pi-run-timer"
  "git:github.com/MatheusBBarni/pi-supergrok-usage"
)

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

FAILED_STEPS=()

run_step() {
  local name="$1"
  shift

  echo
  echo "==> $name"
  if "$@"; then
    echo "OK $name"
    return 0
  fi

  local status=$?
  echo "FAILED $name (exit $status). Re-run will skip anything already installed."
  FAILED_STEPS+=("$name")
  return 0
}

finish_steps() {
  if ((${#FAILED_STEPS[@]} > 0)); then
    echo
    echo "Finished with failures: ${FAILED_STEPS[*]}"
    echo "Re-run this script; completed installs will be skipped."
    return 1
  fi

  echo
  echo "Done"
}

pi_has_package() {
  local package="$1"
  local settings="$HOME/.pi/agent/settings.json"

  [[ -f "$settings" ]] || return 1
  have_cmd python3 || return 1

  python3 - "$settings" "$package" <<'PY'
import json
import sys

path, wanted = sys.argv[1], sys.argv[2]
try:
    with open(path, encoding="utf-8") as handle:
        data = json.load(handle)
except Exception:
    raise SystemExit(1)

packages = data.get("packages") or []
if wanted in packages:
    raise SystemExit(0)

wanted_name = wanted.rstrip("/").rsplit("/", 1)[-1]
wanted_name = wanted_name.split(":")[-1]
for package in packages:
    name = str(package).rstrip("/").rsplit("/", 1)[-1]
    name = name.split(":")[-1]
    if name == wanted_name:
        raise SystemExit(0)

raise SystemExit(1)
PY
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

# Optional $1 is a theme name. Empty keeps whatever theme is already set
# (Omarchy writes omarchy-system via omarchy-theme-set-pi).
configure_pi() {
  echo "Configuring Pi"

  if ! command -v pi >/dev/null 2>&1; then
    echo "Pi CLI not found; skipping Pi extension setup"
    return
  fi

  local theme="${1:-}"
  local package

  for package in "${PI_PACKAGES[@]}"; do
    if pi_has_package "$package"; then
      echo "Pi package already installed: $package"
      continue
    fi

    echo "Installing Pi package: $package"
    if ! pi install "$package"; then
      echo "Failed to install $package; continuing"
    fi
  done

  local settings_file="$HOME/.pi/agent/settings.json"
  mkdir -p "$HOME/.pi/agent"

  if command -v python3 >/dev/null 2>&1; then
    PI_THEME="$theme" python3 - "$settings_file" "${PI_PACKAGES[@]}" <<'PY'
import json
import os
import sys

settings_path = sys.argv[1]
required_packages = sys.argv[2:]
theme = os.environ.get("PI_THEME", "")

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

def package_name(value):
    name = str(value).rstrip("/").rsplit("/", 1)[-1]
    return name.split(":")[-1]

existing_names = {package_name(package) for package in packages}
for package in required_packages:
    if package in packages or package_name(package) in existing_names:
        continue
    packages.append(package)
    existing_names.add(package_name(package))

current["packages"] = packages
if theme:
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
  local agent
  for agent in "$DOTFILES_DIR"/ai/agents/pi/*.md; do
    [[ -f "$agent" ]] || continue
    link_file "$agent" "$HOME/.pi/agent/agents/$(basename "$agent")"
  done

  mkdir -p "$HOME/.pi/agent/extensions"
  local extension
  shopt -s nullglob
  for extension in "$DOTFILES_DIR"/ai/extensions/pi/*; do
    link_file "$extension" "$HOME/.pi/agent/extensions/$(basename "$extension")"
  done
  shopt -u nullglob

  mkdir -p "$HOME/.pi/agent/skills"
  local skill
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

  if [[ -f "$DOTFILES_DIR/ai/codex/install-tui-status-line.sh" ]]; then
    bash "$DOTFILES_DIR/ai/codex/install-tui-status-line.sh"
  fi

  mkdir -p "$HOME/.codex/agents"
  local agent
  for agent in "$DOTFILES_DIR"/ai/agents/codex/*.toml; do
    [[ -f "$agent" ]] || continue
    link_file "$agent" "$HOME/.codex/agents/$(basename "$agent")"
  done

  mkdir -p "$HOME/.codex/skills"
  local skill
  for skill in "$DOTFILES_DIR"/ai/skills/*; do
    [[ -d "$skill" ]] || continue
    link_file "$skill" "$HOME/.codex/skills/$(basename "$skill")"
  done
}

configure_claude() {
  echo "Configuring Claude Code"

  mkdir -p "$HOME/.claude"

  if [[ -f "$DOTFILES_DIR/ai/claude/CLAUDE.md" ]]; then
    link_file "$DOTFILES_DIR/ai/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
  fi

  mkdir -p "$HOME/.claude/skills"
  local skill
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

configure_herdr() {
  echo "Configuring herdr"

  if [[ -f "$DOTFILES_DIR/herdr/config.toml" ]]; then
    link_file "$DOTFILES_DIR/herdr/config.toml" "$HOME/.config/herdr/config.toml"
  fi

  if [[ -f "$DOTFILES_DIR/herdr/move-space.py" ]]; then
    link_file "$DOTFILES_DIR/herdr/move-space.py" "$HOME/.config/herdr/move-space.py"
    chmod +x "$DOTFILES_DIR/herdr/move-space.py"
  fi
}

# Browser session yt-dlp should reuse for YouTube Music.
cliamp_cookies_from() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    if [[ -d "$HOME/Library/Application Support/net.imput.helium" ]]; then
      printf '%s\n' "chrome:~/Library/Application Support/net.imput.helium"
      return
    fi
    if [[ -d "$HOME/Library/Application Support/Google/Chrome" ]]; then
      printf '%s\n' "chrome"
      return
    fi
    if [[ -d "$HOME/Library/Application Support/BraveSoftware/Brave-Browser" ]]; then
      printf '%s\n' "brave"
      return
    fi
    printf '%s\n' "safari"
    return
  fi

  local keyring=""
  if [[ -n "${WAYLAND_DISPLAY:-}" || -d /usr/share/omarchy ]]; then
    keyring="+gnomekeyring"
  fi

  if [[ -d "$HOME/.config/chromium" ]]; then
    printf '%s\n' "chromium${keyring}"
    return
  fi
  if [[ -d "$HOME/.config/google-chrome" ]]; then
    printf '%s\n' "chrome${keyring}"
    return
  fi
  if [[ -d "$HOME/.config/BraveSoftware/Brave-Browser" ]]; then
    printf '%s\n' "brave${keyring}"
    return
  fi
  if [[ -d "$HOME/.mozilla/firefox" ]]; then
    printf '%s\n' "firefox"
    return
  fi

  printf '%s\n' "chrome"
}

# Copy the tracked cliamp config if needed, then fill in YouTube Music cookies.
configure_cliamp() {
  echo "Configuring cliamp (YouTube Music)"

  local config_dir="$HOME/.config/cliamp"
  local config_file="$config_dir/config.toml"
  local template="$DOTFILES_DIR/cliamp/config.toml"
  local cookies

  mkdir -p "$config_dir"

  if [[ ! -f "$config_file" && -f "$template" ]]; then
    cp "$template" "$config_file"
  elif [[ ! -f "$config_file" ]]; then
    cat > "$config_file" <<'EOF'
provider = "ytmusic"

[ytmusic]
expand_playlist = true
EOF
  fi

  cookies="$(cliamp_cookies_from)"

  if command -v python3 >/dev/null 2>&1; then
    python3 - "$config_file" "$cookies" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
cookies = sys.argv[2]
text = path.read_text(encoding="utf-8") if path.exists() else ""
if text and not text.endswith("\n"):
    text += "\n"

lines = text.splitlines(keepends=True)

def is_active_assignment(line, key):
    stripped = line.strip()
    return (
        not stripped.startswith("#")
        and stripped.startswith(key)
        and "=" in stripped
    )

has_provider = any(is_active_assignment(line, "provider") for line in lines)

section_start = None
for i, line in enumerate(lines):
    if line.strip() == "[ytmusic]":
        section_start = i
        break

def section_end(start):
    for j in range(start + 1, len(lines)):
        stripped = lines[j].strip()
        if stripped.startswith("[") and stripped.endswith("]"):
            return j
    return len(lines)

if not has_provider:
    lines.insert(0, 'provider = "ytmusic"\n')
    if section_start is not None:
        section_start += 1

if section_start is None:
    if lines and lines[-1].strip() != "":
        lines.append("\n")
    lines.extend(
        [
            "[ytmusic]\n",
            f'cookies_from = "{cookies}"\n',
            "expand_playlist = true\n",
        ]
    )
else:
    end = section_end(section_start)
    body = lines[section_start + 1 : end]
    if not any(is_active_assignment(line, "cookies_from") for line in body):
        lines.insert(section_start + 1, f'cookies_from = "{cookies}"\n')

path.write_text("".join(lines), encoding="utf-8")
print(f"YouTube Music cookies_from={cookies}")
PY
  elif ! grep -q '^[[:space:]]*cookies_from[[:space:]]*=' "$config_file"; then
    if ! grep -q '^\[ytmusic\]' "$config_file"; then
      printf '\n[ytmusic]\ncookies_from = "%s"\n' "$cookies" >> "$config_file"
    else
      printf 'cookies_from = "%s"\n' "$cookies" >> "$config_file"
    fi
    echo "YouTube Music cookies_from=$cookies"
  fi

  if ! have_cmd yt-dlp; then
    echo "yt-dlp is not on PATH. YouTube Music playback needs it."
  fi
}
