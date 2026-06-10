# Claude Code Configuration

This directory contains Claude Code configuration files for personalized development experience.

## Files

- **statusline-command.sh** - Custom status line script that displays:
  - Folder name (green)
  - Git branch (cyan)
  - Context percentage (yellow)
  - 5-hour token usage (red)

- **settings.json** - Claude Code settings template

## Installation

### Option 1: Symlink (Recommended for dotfiles sync)

```bash
# Create symlink from ~/.claude/statusline-command.sh to this file
ln -s ~/.dotfiles/ai/claude/statusline-command.sh ~/.claude/statusline-command.sh
```

Then merge the relevant parts of `settings.json` into `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.dotfiles/ai/claude/statusline-command.sh"
  }
}
```

### Option 2: Direct Copy

```bash
cp statusline-command.sh ~/.claude/
cp settings.json ~/.claude/  # or merge contents
```

## Colors

The status line uses the following colors:
- **Folder name**: Green
- **Git branch**: Cyan
- **Context (ctx%)**: Yellow
- **5-hour usage (5h%)**: Red

To customize colors, edit the ANSI color codes at the top of `statusline-command.sh`.

## Status Line Format

Example output:
```
multiagent-harness  feat/my-feature  ctx:42%  5h:18%
```

Each element appears only if available:
- Folder name: always shown
- Branch: hidden outside git repositories
- Context %: shown after first API response
- 5h usage: shown for Claude.ai subscribers after first API response
