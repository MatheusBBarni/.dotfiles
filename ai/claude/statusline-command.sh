#!/bin/sh
input=$(cat)

# ANSI color codes
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
RESET='\033[0m'

folder=$(echo "$input" | jq -r '.workspace.current_dir' | xargs basename)

branch=$(git -C "$(echo "$input" | jq -r '.workspace.current_dir')" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)

used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
five_hour=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')

# Folder (green)
parts=$(printf "${GREEN}%s${RESET}" "$folder")

# Git branch (cyan)
[ -n "$branch" ] && parts="$parts  $(printf "${CYAN}%s${RESET}" "$branch")"

# Context percentage (yellow)
if [ -n "$used" ]; then
  parts="$parts  $(printf "${YELLOW}ctx:%s%%${RESET}" "$(printf '%.0f' "$used")")"
fi

# 5-hour rate limit (red)
if [ -n "$five_hour" ]; then
  parts="$parts  $(printf "${RED}5h:%s%%${RESET}" "$(printf '%.0f' "$five_hour")")"
fi

printf "%b" "$parts"
