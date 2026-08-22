# 🎯 Dotfiles

Personal configuration files and setup scripts for macOS, Linux, and Omarchy.

## Features

- **macOS Bootstrap** (`macos-setup.sh`) - apps, developer tools, and configs
- **Omarchy Bootstrap** (`omarchy-setup.sh`) - personal overlay only; skips agents and packages Omarchy already ships
- **Linux Bootstrap** (`linux-setup.sh`) - full Arch/Linux setup for non-Omarchy boxes
- **Editor Configs** - Vim, Neovim (better-vim), VSCode, and Zed
- **Terminal Configs** - zsh, Warp, Ghostty, and tmux
- **AI Integration** - Pi extensions, Codex/Claude configs, and shared skills

## How to use

`bootstrap.sh` picks the setup script from a target name.
On a new machine it clones this repo to `~/.dotfiles` (or reuses that clone), then runs the matching setup.
If you already have the repo checked out, it uses that copy instead.

### One-liner

Args after `bash -s --` are required so the target reaches the script.

```bash
curl -fsSL https://raw.githubusercontent.com/MatheusBBarni/.dotfiles/master/bootstrap.sh \
  | bash -s -- omarchy --bettervim-license YOUR_LICENSE_KEY
```

### From a clone

```bash
git clone https://github.com/MatheusBBarni/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./bootstrap.sh omarchy --bettervim-license YOUR_LICENSE_KEY
```

Or call a setup script directly:

```bash
./omarchy-setup.sh --bettervim-license YOUR_LICENSE_KEY
./macos-setup.sh --bettervim-license YOUR_LICENSE_KEY
./linux-setup.sh --bettervim-license YOUR_LICENSE_KEY
```

### Targets

| Target | Script | Use when |
|--------|--------|----------|
| `mac`, `macos` | `macos-setup.sh` | macOS |
| `linux` | `linux-setup.sh` | Arch/Linux that is not Omarchy |
| `omarchy` | `omarchy-setup.sh` | Omarchy. Skips agents and packages the distro already ships |

### Bootstrap flags

| Flag | What it does |
|------|----------------|
| `--ssh` | Clone with `git@github.com` instead of HTTPS |
| `--dir PATH` | Clone or reuse this directory instead of `~/.dotfiles` |
| `-h`, `--help` | Show help |

Anything after the target is passed through to the setup script.

### Setup flags

| Flag | What it does |
|------|----------------|
| `--bettervim-license LICENSE` | Required the first time bettervim is installed. Safe to omit on re-runs if it is already there |
| `-h`, `--help` | Show help |

### Re-runs

Setup scripts skip tools, fonts, themes, and Pi packages that are already installed.
If a step fails, run the same command again.

When it finishes, reload the shell:

```bash
exec zsh
```

## Directory Structure

| Path | Purpose |
|------|---------|
| `bootstrap.sh` | Curl-friendly launcher: `mac`, `linux`, or `omarchy` |
| `omarchy-setup.sh` | Omarchy overlay (does not reinstall shipped agents) |
| `macos-setup.sh` | macOS bootstrap |
| `linux-setup.sh` | Generic Arch/Linux bootstrap |
| `setup-lib.sh` | Shared helpers, including the Pi extension install list |
| `ai/` | Codex, Claude, Pi agents/skills, and local Pi extensions |
| `better-vim/` | Neovim + Lua configuration with plugins |
| `cmux/` | CMux multiplexer configuration |
| `ghostty/` | Ghostty terminal emulator themes and configs |
| `pi-subagents/` | Pi Subagents setup and documentation |
| `vscode/` | VSCode settings, keybindings, and extensions |
| `vscode-snippets/` | Code snippets for VSCode |
| `warp/` | Warp terminal keybindings |
| `zed/` | Zed editor settings and keybindings |
| `.zshrc` | Zsh shell configuration |
| `.tmux.conf` | Tmux configuration |
| `init.vim` | Vim/Neovim init configuration |

## Editor Configurations

### Vim/Neovim
- **File:** `init.vim` + `better-vim/` directory
- **Features:** Lua support, plugin management, custom overrides

### VSCode
- **Keybindings:** `vscode/keybindings.json`
- **Settings:** `vscode/settings.json`
- **Extensions:** Install via `vscode/vscode-extensions.sh`
- **Snippets:** Custom snippets in `vscode-snippets/`

### Zed
- **Keybindings:** `zed/keymap.json`
- **Settings:** `zed/settings.json`
- **Extensions:** Auto-install via `zed/auto-install-extensions.json`
- **Export:** Export settings with `zed/export-zed-config.sh`

### Warp Terminal
- **Keybindings:** `warp/keybindings.yaml`

## System Integration

### Dock Apps (macOS)
The setup script configures these apps on the dock:
- Helium
- Zed
- YouTube Music
- Tailscale
- Docker
- Discord
- System Settings

### Themes
- **Ghostty:** Eldritch theme with custom icons

## Customization

- **Shell:** Edit `.zshrc` for custom aliases, functions, and environment variables
- **Tmux:** Modify `.tmux.conf` for keybindings and appearance
- **Editors:** Update configurations in respective editor directories
- **Bootstrap:** Modify setup scripts to add/remove packages and configurations

## Requirements

- **macOS:** 10.15+ (tested on recent versions)
- **Linux:** Ubuntu 20.04+ or equivalent
- **Tools:** Git, curl, basic development tools

## License

Personal configuration. Use as reference for your own dotfiles.
