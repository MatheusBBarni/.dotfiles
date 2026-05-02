# pi-subagents config

This repo installs the `pi-subagents` Pi extension during macOS setup:

```sh
pi install npm:pi-subagents
```

Pi subagent definitions are stored with the rest of the personal agent configs:

- `ai/agents/pi/the-engineer.md`
- `ai/agents/pi/code-reviewer.md`

`macos-setup.sh` links them into:

```text
~/.pi/agent/agents/
```

After setup, Pi can use these agents by name:

```text
Use TheEngineer to implement this plan.
Use CodeReviewer to review this diff.
```

The extension also ships its own builtin agents like `scout`, `planner`,
`worker`, `reviewer`, `oracle`, and `delegate`. These custom agents live at the
user scope and override builtins only if the names collide.
