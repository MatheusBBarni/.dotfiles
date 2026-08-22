# 🎯 Dotfiles

Personal configuration files and setup scripts for macOS, Linux, and Omarchy.

## Features

- **macOS Bootstrap** (`macos-setup.sh`) - apps, developer tools, and configs
- **Omarchy Bootstrap** (`omarchy-setup.sh`) - personal overlay only; skips agents and packages Omarchy already ships
- **Linux Bootstrap** (`linux-setup.sh`) - full Arch/Linux setup for non-Omarchy boxes
- **Editor Configs** - Vim, Neovim (better-vim), VSCode, and Zed
- **Terminal Configs** - zsh, Warp, Ghostty, and tmux
- **AI Integration** - Pi extensions, Codex/Claude configs, and shared skills

## Quick Start

### macOS Setup

```bash
./macos-setup.sh [options]
```

**Options:**
- `--bettervim-license LICENSE` - License key for bettervim installation
- `-h, --help` - Show help

**Example:**
```bash
./macos-setup.sh --bettervim-license YOUR_LICENSE_KEY
```

### Omarchy Setup

Omarchy already installs Pi, Claude, Codex, OpenCode, herdr, docker, nvim, and the usual CLI tools via mise / `omarchy-base.packages`.
This script only adds the gaps (zsh, bun, rust, android, bettervim, Pi extensions, personal configs) and applies Omarchy's built-in Catppuccin dark theme.

```bash
./omarchy-setup.sh --bettervim-license YOUR_LICENSE_KEY
```

### Linux Setup (non-Omarchy)

```bash
./linux-setup.sh --bettervim-license YOUR_LICENSE_KEY
```

## Directory Structure

| Path | Purpose |
|------|---------|
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

## Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/MatheusBBarni/.dotfiles.git
   cd .dotfiles
   ```

2. Run the appropriate setup script:
   ```bash
   # macOS
   ./macos-setup.sh --bettervim-license YOUR_LICENSE

   # Omarchy
   ./omarchy-setup.sh --bettervim-license YOUR_LICENSE

   # Other Linux
   ./linux-setup.sh --bettervim-license YOUR_LICENSE
   ```

3. Restart your terminal or reload your shell:
   ```bash
   exec zsh  # or your preferred shell
   ```

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

Personal configuration — use as reference for your own dotfiles.
