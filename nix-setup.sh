#!/usr/bin/env bash
set -euo pipefail

# Compatibility wrapper. The NixOS bootstrap lives in nixos-setup.sh.
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/nixos-setup.sh" "$@"
