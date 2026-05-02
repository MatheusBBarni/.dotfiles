# cmux config

cmux config is split across two locations:

- cmux app settings: `~/.config/cmux/settings.json`
- terminal settings used by cmux: `~/.config/ghostty/config`

cmux may also keep fallback settings in:

- `~/Library/Application Support/com.cmuxterm.app/settings.json`
- `~/Library/Application Support/com.mitchellh.ghostty/config`

`macos-setup.sh` links the files below when they exist:

- `cmux/settings.json` -> `~/.config/cmux/settings.json`
- `cmux/ghostty/config` -> `~/.config/ghostty/config`

## Export from an already configured Mac

Run this from the repo root on the Mac where cmux is already configured:

```sh
mkdir -p cmux/ghostty

if [ -f "$HOME/.config/cmux/settings.json" ]; then
  cp "$HOME/.config/cmux/settings.json" cmux/settings.json
elif [ -f "$HOME/Library/Application Support/com.cmuxterm.app/settings.json" ]; then
  cp "$HOME/Library/Application Support/com.cmuxterm.app/settings.json" cmux/settings.json
else
  echo "No cmux settings.json found"
fi

if [ -f "$HOME/.config/ghostty/config" ]; then
  cp "$HOME/.config/ghostty/config" cmux/ghostty/config
elif [ -f "$HOME/Library/Application Support/com.mitchellh.ghostty/config" ]; then
  cp "$HOME/Library/Application Support/com.mitchellh.ghostty/config" cmux/ghostty/config
else
  echo "No Ghostty config found"
fi
```

Review the copied files before committing. In particular, check for local paths,
socket settings, passwords, tokens, and machine-specific values.

After exporting, run:

```sh
git diff -- cmux
```

On a new Mac, run the setup script from the repo root:

```sh
./macos-setup.sh
```

To reload cmux without restarting the app:

```sh
cmux reload-config
```

You can also use `Cmd+Shift+,` inside cmux.
