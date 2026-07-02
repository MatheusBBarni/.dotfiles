#!/bin/sh
input=$(cat)

# ANSI color codes
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
RESET='\033[0m'

folder=$(echo "$input" | jq -r '.workspace.current_dir' | xargs basename)

branch=$(git -C "$(echo "$input" | jq -r '.workspace.current_dir')" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
if [ ${#branch} -gt 30 ]; then
  branch="$(echo "$branch" | cut -c1-27)..."
fi

model=$(echo "$input" | jq -r '.model.display_name // empty' | awk '{print $1}')
effort=$(echo "$input" | jq -r '.effort.level // empty')

used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
five_hour=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')

# Folder (green)
parts=$(printf "${GREEN}%s${RESET}" "$folder")

# Git branch (cyan)
[ -n "$branch" ] && parts="$parts  $(printf "${CYAN}%s${RESET}" "$branch")"

# Model name (magenta), with effort appended when available
if [ -n "$model" ]; then
  if [ -n "$effort" ]; then
    parts="$parts  $(printf "${MAGENTA}%s (%s)${RESET}" "$model" "$effort")"
  else
    parts="$parts  $(printf "${MAGENTA}%s${RESET}" "$model")"
  fi
fi

# Context percentage (yellow)
if [ -n "$used" ]; then
  parts="$parts  $(printf "${YELLOW}ctx:$(printf '%.0f' "$used")%%${RESET}")"
fi

# 5-hour rate limit (red)
if [ -n "$five_hour" ]; then
  parts="$parts  $(printf "${RED}5h:$(printf '%.0f' "$five_hour")%%${RESET}")"
fi

printf "%b" "$parts"
