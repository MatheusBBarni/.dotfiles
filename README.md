# 🎯 Dotfiles

Personal configuration files and setup scripts for a fully automated macOS and Linux development environment.

## Features

- **macOS Bootstrap** (`macos-setup.sh`) — Complete system setup with apps, developer tools, and configurations
- **Linux Bootstrap** (`linux-setup.sh`) — Essential packages and configurations for Linux systems
- **Editor Configs** — Vim, Neovim (better-vim), VSCode, and Zed editor setups
- **Terminal Configs** — zsh, Warp terminal, Ghostty, and tmux configurations
- **CLI Tools** — CMux and Pi Subagents configurations
- **AI Integration** — Codex CLI, Claude Code, and AI-related tooling

## Quick Start

### macOS Setup

```bash
./macos-setup.sh [options]
```

**Options:**
- `--atlas-bookmarks-html PATH` — Import bookmarks into Atlas (Brave/Chrome export)
- `--bettervim-license LICENSE` — License key for bettervim installation
- `-h, --help` — Show help

**Example:**
```bash
./macos-setup.sh --bettervim-license YOUR_LICENSE_KEY
```

### Linux Setup

```bash
./linux-setup.sh
```

## Directory Structure

| Directory | Purpose |
|-----------|---------|
| `ai/` | AI-related tools plus Codex and Claude Code configurations |
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
- ChatGPT Atlas
- cmux
- Zed
- Codex
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
   chmod +x macos-setup.sh
   ./macos-setup.sh --bettervim-license YOUR_LICENSE
   
   # Linux
   chmod +x linux-setup.sh
   ./linux-setup.sh
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
