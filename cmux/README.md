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

Use this when one Mac already has cmux configured and you want to save that
config into this dotfiles repo.

Run these commands on the Mac where cmux already works.

First, open Terminal and go to this repo:

```sh
cd ~/.dotfiles
```

If your clone lives somewhere else, use that path instead. For example:

```sh
cd ~/projects/.dotfiles
```

Then run this export block from inside the repo:

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

The commands above copy files from your Mac's live cmux/Ghostty config folders
into this repo:

- from `~/.config/cmux/settings.json` to `cmux/settings.json`
- from `~/.config/ghostty/config` to `cmux/ghostty/config`

Review the copied files before committing. In particular, check for local paths,
socket settings, passwords, tokens, and machine-specific values.

Still on the configured Mac, check what changed:

```sh
git diff -- cmux
```

If the diff looks right, commit and push it:

```sh
git add cmux
git commit -m "feat: add cmux config"
git push
```

## Install on a new Mac

On the new Mac, clone or update this repo first:

```sh
git clone git@github.com:MatheusBBarni/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

If the repo is already cloned:

```sh
cd ~/.dotfiles
git pull
```

Then run the setup script from inside the repo:

```sh
./macos-setup.sh
```

The setup script links the committed cmux files into the live config paths.

To reload cmux without restarting the app:

```sh
cmux reload-config
```

You can also use `Cmd+Shift+,` inside cmux.
