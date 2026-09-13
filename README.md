# .dotfiles

<!-- markdownlint-disable MD013 -->
Cross-platform shell, editor, terminal, and workstation setup for macOS, Arch Linux, Omarchy, NixOS, and a minimal Windows gaming machine.

> [!NOTE]
> The Windows setup is intentionally separate from the developer-oriented macOS and Linux setups. It does not install Claude, Codex, OMP, Pi, or other agent tooling.

## Quick navigation

- [What is included](#what-is-included)
- [Common bootstrap](#common-bootstrap)
- [macOS](#macos)
- [Linux](#linux)
  - [Omarchy](#omarchy)
  - [NixOS](#nixos)
- [Windows gaming](#windows-gaming)
- [After setup](#after-setup)
- [Repository layout](#repository-layout)
- [Troubleshooting](#troubleshooting)

## What is included

- Platform setup scripts with package installation and configuration steps
- Zsh, Oh My Zsh, tmux, Ghostty, Warp, and CMux configuration
- Neovim, VS Code, and Zed configuration
- OMP, Pi, Codex, Claude Code, and shared agent configuration for Unix setups
- CLIAMP configured for YouTube Music using an existing browser session
- NixOS Home Manager and optional Hyprland modules
- A minimal Windows gaming setup with Steam, Brave, Battle.net, and RubinOT

## Requirements

| Platform | Requirements |
| --- | --- |
| macOS | macOS 10.15+, internet access, administrator access, Git/curl or Xcode Command Line Tools |
| Linux | Arch Linux, internet access, `sudo`, and a working `pacman` environment |
| Omarchy | An existing Omarchy installation |
| NixOS | An existing NixOS installation with flakes enabled or available |
| Windows | Windows 10/11 64-bit and WinGet/App Installer |

The macOS and Linux scripts require a bettervim license. Omarchy and NixOS require it only when bettervim is not already installed.

> [!WARNING]
> Setup scripts install packages, change shell/configuration files, and download installers from upstream projects. Review the script for your platform before running it on a machine with existing configuration.

## Common bootstrap

`bootstrap.sh` is a Bash launcher for macOS, Linux, Omarchy, and NixOS. It clones this repository to `~/.dotfiles` when needed, reuses an existing clone, and then runs the selected setup script.

```bash
git clone https://github.com/MatheusBBarni/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./bootstrap.sh mac --bettervim-license YOUR_LICENSE_KEY
```

### Bootstrap targets

| Target | Script | Platform |
| --- | --- | --- |
| `mac`, `macos`, `osx`, `darwin` | `macos-setup.sh` | macOS |
| `linux` | `linux-setup.sh` | Generic Arch Linux |
| `omarchy` | `omarchy-setup.sh` | Omarchy |
| `nix`, `nixos` | `nixos-setup.sh` | NixOS |

### Bootstrap flags

| Flag | Description |
| --- | --- |
| `--dir PATH` | Clone or reuse a different directory instead of `~/.dotfiles` |
| `--ssh` | Clone using `git@github.com:MatheusBBarni/.dotfiles.git` instead of HTTPS |
| `-h`, `--help` | Show bootstrap help |

Arguments after the target are passed to that platform's setup script.

## macOS

`macos-setup.sh` installs a complete development workstation:

- Homebrew, CLI utilities, zsh, Oh My Zsh, and shell plugins
- Node.js 24 through nvm, Bun, pnpm, Rust, Java/Kotlin, Go, OCaml, and Docker
- bettervim, OMP, Pi packages, Codex and Claude Code configuration
- Zed, Ghostty, Helium, Bitwarden, Discord, Tailscale, Android Studio, Handy, and other desktop apps
- Fonts, Dock entries, CLIAMP, and tracked configuration files

### macOS one-liner

```bash
curl -fsSL https://raw.githubusercontent.com/MatheusBBarni/.dotfiles/master/bootstrap.sh \
  | bash -s -- mac --bettervim-license YOUR_LICENSE_KEY
```

### macOS from a clone

```bash
./macos-setup.sh --bettervim-license YOUR_LICENSE_KEY
```

### macOS flags

| Flag | Description |
| --- | --- |
| `--bettervim-license LICENSE` | bettervim license key; required |
| `-h`, `--help` | Show setup help |

Xcode is installed when the Mac App Store is signed in. The script skips it and prints a note otherwise.

## Linux

`linux-setup.sh` targets generic Arch Linux. It uses official packages through `pacman` and AUR packages through `yay`, bootstrapping `yay` when necessary.

It installs a development workstation similar to macOS, including zsh, Node.js 24, Bun, Rust, Java/Kotlin, Go, Docker, bettervim, OMP, Pi, Codex, Claude Code, Zed, Ghostty, CLIAMP, Tailscale, and desktop applications.

### Linux one-liner

```bash
curl -fsSL https://raw.githubusercontent.com/MatheusBBarni/.dotfiles/master/bootstrap.sh \
  | bash -s -- linux --bettervim-license YOUR_LICENSE_KEY
```

### Linux from a clone

```bash
./linux-setup.sh --bettervim-license YOUR_LICENSE_KEY
```

### Linux flags

| Flag | Description |
| --- | --- |
| `--bettervim-license LICENSE` | bettervim license key; required |
| `-h`, `--help` | Show setup help |

> [!IMPORTANT]
> This is an Arch/pacman setup. It is not an Ubuntu or Debian installer.

## Omarchy

Omarchy is handled as a separate Linux overlay. `omarchy-setup.sh` assumes the distro already provides many base packages and agents, so it installs only the missing tools and personal configuration.

It skips packages Omarchy already ships, including Pi, Claude, Codex, OpenCode, Herdr, Docker, Git, Neovim, GitHub CLI, common shell utilities, Chromium, and tmux. It adds the remaining development tools, bettervim, OMP configuration, Zed, Ghostty, Tailscale, Android Studio, CLIAMP, fonts, and personal files.

### Omarchy one-liner

```bash
curl -fsSL https://raw.githubusercontent.com/MatheusBBarni/.dotfiles/master/bootstrap.sh \
  | bash -s -- omarchy --bettervim-license YOUR_LICENSE_KEY
```

### Omarchy from a clone

```bash
./omarchy-setup.sh --bettervim-license YOUR_LICENSE_KEY
```

### Omarchy flags

| Flag | Description |
| --- | --- |
| `--bettervim-license LICENSE` | bettervim license key when bettervim is not installed |
| `-h`, `--help` | Show setup help |

The script applies Omarchy's built-in Catppuccin dark theme, configures CLIAMP for YouTube Music, and leaves existing distro-managed agents untouched.

## NixOS

`nixos-setup.sh` is for an existing NixOS host. It:

1. Writes the NixOS drop-in and optionally runs `nixos-rebuild switch`.
2. Applies the Home Manager flake in `nix/` with the workstation package set.
3. Links shell, editor, terminal, agent, OMP, CLIAMP, and desktop configuration.
4. Enables the optional Hyprland session, PipeWire, Docker, Tailscale, zsh, and related services.

`nix-setup.sh` is a compatibility wrapper for `nixos-setup.sh`.

### NixOS one-liner

```bash
curl -fsSL https://raw.githubusercontent.com/MatheusBBarni/.dotfiles/master/bootstrap.sh \
  | bash -s -- nixos --bettervim-license YOUR_LICENSE_KEY
```

### NixOS from a clone

```bash
./nixos-setup.sh --bettervim-license YOUR_LICENSE_KEY
```

### NixOS flags

| Flag | Description |
| --- | --- |
| `--bettervim-license LICENSE` | bettervim license key when bettervim is not installed |
| `--no-hyprland` | Skip the Hyprland compositor module |
| `--no-rebuild` | Do not write `/etc/nixos` imports or run `nixos-rebuild` |
| `-h`, `--help` | Show setup help |

After login, select `Hyprland (UWSM)` if enabled. Run `exec zsh` and `tailscale up` when appropriate.

## Windows gaming

`windows-setup.ps1` is a PowerShell script and is run directly. It is not dispatched by `bootstrap.sh`.

The default setup:

- Verifies 64-bit Windows and WinGet availability
- Installs Steam, Brave, and Battle.net through exact WinGet package IDs
- Downloads RubinOT from its official download endpoint and opens the installer interactively
- Does not install developer tools or agent harnesses
- Skips debloating unless explicitly requested

### Windows one-liner

```powershell
& ([scriptblock]::Create((irm "https://raw.githubusercontent.com/MatheusBBarni/.dotfiles/master/windows-setup.ps1")))
```

### Windows one-liner with debloat

```powershell
& ([scriptblock]::Create((irm "https://raw.githubusercontent.com/MatheusBBarni/.dotfiles/master/windows-setup.ps1"))) -RunDebloat
```

### Windows from a clone

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\windows-setup.ps1
```

### Windows flags

| Flag | Description |
| --- | --- |
| `-RunDebloat` | Run Win11Debloat's recommended settings without removing apps |
| `-RemoveBloatApps` | With `-RunDebloat`, also remove Win11Debloat's default pre-installed app selection |
| `-WhatIf` | Print actions without installing anything |

`-RemoveBloatApps` requires `-RunDebloat` and may request administrator access. Review the upstream [Win11Debloat app list](https://github.com/Raphire/Win11Debloat/blob/master/Config/Apps.json) before using it.

If WinGet is missing, install or update [App Installer](https://apps.microsoft.com/detail/9NBLGGH4NNS1), then rerun the script.

## After setup

Unix setup scripts are safe to rerun; completed package and configuration steps are skipped where the platform supports it. If a step fails, rerun the same command.

Reload the shell after setup:

```bash
exec zsh
```

Useful follow-up actions:

- Sign in to YouTube in the browser used by CLIAMP so cookie-based playback works.
- Run `tailscale up` if the machine should join the tailnet.
- On NixOS with Hyprland enabled, log out and select the Hyprland UWSM session.
- On macOS, review the Dock after the app installations complete.

## Repository layout

| Path | Purpose |
| --- | --- |
| `bootstrap.sh` | Curl-friendly Unix setup launcher |
| `macos-setup.sh` | Full macOS workstation setup |
| `linux-setup.sh` | Full generic Arch Linux setup |
| `omarchy-setup.sh` | Omarchy-specific personal overlay |
| `nixos-setup.sh` | NixOS system and Home Manager setup |
| `windows-setup.ps1` | Minimal Windows gaming setup |
| `setup-lib.sh` | Shared Unix helpers and Pi/OMP configuration |
| `ai/` | Agent definitions, skills, extensions, and tool configuration |
| `nix/` | Nix flake, Home Manager, Hyprland, and NixOS modules |
| `zed/` | Zed settings, keymap, themes, snippets, and export tools |
| `ghostty/` | Ghostty config, themes, and icons |
| `herdr/` | Herdr config and OMP integration |
| `cliamp/` | CLIAMP YouTube Music configuration template |
| `vscode/` | VS Code settings and extension installer |
| `better-vim/` | Neovim Lua configuration and plugin files |
| `.zshrc` | Zsh aliases, environment setup, and integrations |
| `.tmux.conf` | Tmux keybindings and plugins |

## Troubleshooting

Show platform-specific options before installing:

```bash
./macos-setup.sh --help
./linux-setup.sh --help
./omarchy-setup.sh --help
./nixos-setup.sh --help
```

For Windows:

```powershell
Get-Help .\windows-setup.ps1 -Full
.\windows-setup.ps1 -WhatIf
```

Common fixes:

- **bettervim fails:** rerun with `--bettervim-license YOUR_LICENSE_KEY`.
- **Arch package installation fails:** confirm `sudo pacman -Syu` works, then rerun the script.
- **NixOS rebuild fails:** rerun with `--no-rebuild` to apply the user-level Home Manager and configuration steps separately.
- **Windows WinGet is missing:** install or update App Installer, then rerun.
- **CLIAMP cannot play YouTube Music:** sign in to YouTube in the detected browser and rerun the setup.
