# Codex Configuration

`tui-status-line.toml` defines the shared Codex TUI status line:

```toml
[tui]
status_line = ["project-name", "git-branch", "model-with-reasoning", "context-used", "five-hour-limit"]
```

`install-tui-status-line.sh` installs that setting into
`~/.codex/config.toml`. It creates the config when it is absent; otherwise it
updates only `tui.status_line`, retaining the rest of the user-owned config and
writing a timestamped backup before a change.

Both `macos-setup.sh` and `linux-setup.sh` invoke the installer from
`configure_codex`.
