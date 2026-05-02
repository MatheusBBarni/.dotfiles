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
8. Open Codex with a prompt that starts with `/goal`.

On macOS, the extension writes and opens a `.command` file so Codex starts in a
separate terminal. On other platforms, it returns the command to run manually.
