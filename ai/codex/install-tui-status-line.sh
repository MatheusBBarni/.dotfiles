#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$SCRIPT_DIR/tui-status-line.toml"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
TARGET="$CODEX_HOME/config.toml"

if [[ ! -f "$SOURCE" ]]; then
  echo "Codex status-line source is missing: $SOURCE" >&2
  exit 1
fi

STATUS_LINE="$(awk '
  /^[[:space:]]*status_line[[:space:]]*=/ {
    sub(/^[[:space:]]*/, "")
    print
    exit
  }
' "$SOURCE")"

if [[ -z "$STATUS_LINE" ]]; then
  echo "Codex status-line source does not define status_line" >&2
  exit 1
fi

mkdir -p "$CODEX_HOME"

if [[ ! -e "$TARGET" && ! -L "$TARGET" ]]; then
  cp "$SOURCE" "$TARGET"
  chmod 600 "$TARGET"
  echo "Created Codex status-line config at $TARGET"
  exit 0
fi

if [[ ! -f "$TARGET" ]]; then
  echo "Codex config is not a regular file: $TARGET" >&2
  exit 1
fi

# A multiline value needs a TOML-aware editor. Refuse it rather than risking
# unrelated config while replacing this single setting.
if ! awk '
  /^[[:space:]]*\[tui\][[:space:]]*(#.*)?$/ {
    in_tui = 1
    next
  }
  /^[[:space:]]*\[/ {
    in_tui = 0
    saw_table = 1
    next
  }
  !saw_table && /^[[:space:]]*tui\.status_line[[:space:]]*=/ && $0 !~ /\]/ {
    exit 1
  }
  in_tui && /^[[:space:]]*status_line[[:space:]]*=/ && $0 !~ /\]/ {
    exit 1
  }
' "$TARGET"; then
  echo "Refusing to replace a multiline Codex status_line in $TARGET" >&2
  exit 1
fi

TEMPORARY="$(mktemp "${TARGET}.tmp.XXXXXX")"
cleanup() {
  rm -f "$TEMPORARY"
}
trap cleanup EXIT

awk -v status_line="$STATUS_LINE" '
  BEGIN {
    root = 1
  }

  function finish_tui() {
    if (in_tui && !wrote_tui_status_line) {
      print status_line
      wrote_tui_status_line = 1
    }
    in_tui = 0
  }

  /^[[:space:]]*\[tui\][[:space:]]*(#.*)?$/ {
    finish_tui()
    found_tui = 1
    in_tui = 1
    root = 0
    print
    next
  }

  !found_tui && !wrote_dotted_status_line && /^[[:space:]]*\[\[?tui\./ {
    print "[tui]"
    print status_line
    print ""
    found_tui = 1
    wrote_tui_status_line = 1
    root = 0
    print
    next
  }

  /^[[:space:]]*\[/ {
    finish_tui()
    root = 0
    print
    next
  }

  root && /^[[:space:]]*tui\.status_line[[:space:]]*=/ {
    if (!wrote_dotted_status_line) {
      print "tui." status_line
      wrote_dotted_status_line = 1
    }
    next
  }

  in_tui && /^[[:space:]]*status_line[[:space:]]*=/ {
    if (!wrote_tui_status_line) {
      print status_line
      wrote_tui_status_line = 1
    }
    next
  }

  { print }

  END {
    finish_tui()
    if (!found_tui && !wrote_dotted_status_line) {
      if (NR > 0) {
        print ""
      }
      print "[tui]"
      print status_line
    }
  }
' "$TARGET" > "$TEMPORARY"

if cmp -s "$TARGET" "$TEMPORARY"; then
  echo "Codex status line is already configured"
  exit 0
fi

BACKUP="${TARGET}.backup.$(date +%Y%m%d%H%M%S)"
cp "$TARGET" "$BACKUP"

if [[ -L "$TARGET" ]]; then
  cp "$TEMPORARY" "$TARGET"
else
  mv "$TEMPORARY" "$TARGET"
fi

echo "Updated Codex status line in $TARGET (backup: $BACKUP)"
