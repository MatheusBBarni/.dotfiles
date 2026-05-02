# Codex goal workflow

This repo includes two Pi extensions:

- `ask-user-question.ts` adds the `ask_user_question` tool for one-question-at-a-time user input.
- `codex-goal-workflow.ts` adds `/codex-goal` and `submit_codex_goal`.

Use it in Pi:

```text
/codex-goal Build a dashboard for tracking failed background jobs
```

The workflow asks Pi to:

1. Use the `grill-with-docs` skill.
2. Explore local code and docs before asking questions.
3. Ask questions through `ask_user_question`.
4. Draft a PRD/SPEC.
5. Call `submit_codex_goal`.
6. Let you edit and approve the final document.
7. Write `.pi/codex-goals/<timestamp>-<title>.md`.
8. Start `codex exec` with a first-line `[[CODEX_LOOP ...]]` activation header.

The extension does not use Codex's interactive `/goal` slash command. Pi cannot
reliably invoke that command inside a subagent. Instead, it starts a headless
Codex CLI task that `codex-loop` can manage through Codex hooks.

Generated artifacts are written under:

```text
.pi/codex-goals/
```

Each run writes:

- `*.md`: the prompt sent to Codex
- `*.log`: stdout/stderr from `codex exec`
- `*.last.md`: the last Codex message written by `--output-last-message`

`macos-setup.sh` installs `codex-loop` with:

```sh
go install github.com/compozy/codex-loop/cmd/codex-loop@latest
codex-loop install
```
