# Local Pi extensions

Published packages are installed by `setup-lib.sh` (`configure_pi`):

- `npm:@matheusbbarni/pi-message-queue`
- `npm:@matheusbbarni/pi-run-timer`
- `npm:@matheusbbarni/pi-stitch-mcp`
- `npm:@matheusbbarni/pi-goal-extension`
- `git:github.com/MatheusBBarni/pi-supergrok-usage`

Drop unpublished `.ts` / `.js` files or extension folders in this directory.
The setup scripts symlink everything here into `~/.pi/agent/extensions/`.
