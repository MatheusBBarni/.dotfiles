# Zed config

Zed user config lives in:

- `~/.config/zed/settings.json`
- `~/.config/zed/keymap.json`
- `~/.config/zed/tasks.json`
- `~/.config/zed/debug.json`
- `~/.config/zed/snippets/`
- `~/.config/zed/themes/`

On Windows, the same user config lives under:

- `%APPDATA%\Zed\settings.json`
- `%APPDATA%\Zed\keymap.json`
- `%APPDATA%\Zed\tasks.json`
- `%APPDATA%\Zed\debug.json`
- `%APPDATA%\Zed\snippets\`
- `%APPDATA%\Zed\themes\`

Installed extensions are machine data, not ideal dotfiles. Export their names and add them to
`settings.json` with `auto_install_extensions`:

```json
{
  "auto_install_extensions": {
    "dockerfile": true,
    "toml": true
  }
}
```

On your Mac, run this from the repo root:

```sh
./zed/export-zed-config.sh
```

On Windows, run this from the repo root in PowerShell:

```powershell
.\zed\export-zed-config.ps1
```

That copies your Zed config into this directory and writes
`auto-install-extensions.json` as a merge helper for `settings.json`.
