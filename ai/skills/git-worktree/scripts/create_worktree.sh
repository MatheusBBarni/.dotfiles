#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: create_worktree.sh [--branch BRANCH] [--base REF] [--detach]

Creates a Git worktree under:
  ${WORKTREE_ROOT:-$HOME/projects/worktree}/{half-uuid}/{repo-folder}

Defaults:
  --base HEAD
  detached worktree unless --branch is provided
USAGE
}

branch=""
base="HEAD"
detach="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --branch)
      [[ $# -ge 2 ]] || { echo "error: --branch requires a value" >&2; exit 2; }
      branch="$2"
      shift 2
      ;;
    --base)
      [[ $# -ge 2 ]] || { echo "error: --base requires a value" >&2; exit 2; }
      base="$2"
      shift 2
      ;;
    --detach)
      detach="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

repo_root="$(git rev-parse --show-toplevel)"
repo_name="$(basename "$repo_root")"
worktree_root="${WORKTREE_ROOT:-$HOME/projects/worktree}"

make_id() {
  if command -v uuidgen >/dev/null 2>&1; then
    uuidgen | tr '[:upper:]' '[:lower:]' | cut -c1-18
  elif [[ -r /proc/sys/kernel/random/uuid ]]; then
    cut -c1-18 /proc/sys/kernel/random/uuid
  elif command -v openssl >/dev/null 2>&1; then
    openssl rand -hex 9
  else
    date +%s%N | cut -c1-18
  fi
}

id="$(make_id)"
target="$worktree_root/$id/$repo_name"

mkdir -p "$(dirname "$target")"

if [[ -n "$branch" && "$detach" == "true" ]]; then
  echo "error: use either --branch or --detach, not both" >&2
  exit 2
fi

if [[ -n "$branch" ]]; then
  git -C "$repo_root" worktree add -b "$branch" "$target" "$base"
else
  git -C "$repo_root" worktree add --detach "$target" "$base"
fi

echo "WORKTREE_PATH=$target"
