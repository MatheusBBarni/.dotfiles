---
name: herdr-issue-lanes
description: Launch one Herdr tab and isolated git worktree per GitHub issue, start a coding agent in each, and send the first prompt. Use when the user wants to work issues in parallel Herdr tabs, spawn issue worktrees, or run pi/codex/claude on a list of issue numbers.
---

# Herdr Issue Lanes

Spin up one isolated lane per GitHub issue in the **current Herdr workspace**: tab `#N`, worktree on `<feat|fix>/issue-N`, requested agent, first prompt.

Announce: "I'm using herdr-issue-lanes (and using-git-worktrees) to launch isolated issue tabs."

## Parameters

Collect these before creating anything. Ask only for missing required values.

| Param | Required | Default | Examples |
| --- | --- | --- | --- |
| **issues** | yes | — | `26,33,32` / `#26 #33` / `fix/26,feat/33` / issue URLs |
| **agent** | yes | `pi` | `pi`, `codex`, `claude`, or any `herdr agent` kind |
| **first prompt** | no | `{url}` | `{url}`, `{number}: {title}`, free text |

Optional extras the user may also give:

- **prefix**: `auto` (default), `fix`, or `feat` for issues without an explicit prefix
- **base**: git ref for new branches (default `origin/main`)
- **agent args**: native CLI flags after `--` (e.g. `--model xai/grok-4.6 --thinking xhigh`)

Prompt placeholders: `{url}`, `{number}`, `{title}`.

## Preconditions

1. `test "${HERDR_ENV:-}" = 1` — if this fails, stop: not inside Herdr.
2. Learn live CLI: `herdr tab`, `herdr worktree`, `herdr agent`, `herdr workspace`.
3. Read caller IDs: `$HERDR_WORKSPACE_ID`, `$HERDR_TAB_ID`, `$HERDR_PANE_ID`.
4. Do **not** ask worktree consent — the user already requested lanes.

## Launch

Prefer the bundled script. It owns the fragile topology (Herdr `worktree create` opens a **workspace**, not a tab).

```bash
python3 ~/.pi/agent/skills/herdr-issue-lanes/scripts/launch_issue_lanes.py \
  --issues 26,33,32,30,31 \
  --agent pi \
  --prompt '{url}' \
  -- --model xai/grok-4.6 --thinking xhigh
```

Keep user focus on the calling pane (`--no-focus` throughout). Do **not** `--wait` on the first prompt.

If the script cannot run, follow [references/workflow.md](references/workflow.md) by hand.

## Branch names

`<prefix>/issue-<number>`

- Explicit token wins: `fix/26` → `fix/issue-26`
- `auto`: `bug` / `fix` / `regression` labels → `fix`, else `feat`
- Forced `--prefix fix|feat` applies to issues without an explicit token

Agent names must be `issue-<number>` (`[a-z][a-z0-9_-]{0,31}`). Tab labels are `#<number>`.

## Isolation rules

- Use Herdr's native `worktree create` (using-git-worktrees Step 1a). Never `git worktree add` while Herdr is available.
- Create sibling worktrees from the repo, even if the caller is already in a linked worktree. Do not nest worktrees.
- Skip parent-side `npm install` / baseline tests. Child agents own setup.
- Do not close tabs, panes, or workspaces you did not create.
- Do not wait for the child agents to finish the issues.

## Report

```
Lane   Tab    Branch            Worktree                              Agent
#26    w5:tB  fix/issue-26      ~/.herdr/worktrees/<repo>/issue-26    issue-26 (pi)
```

First prompt sent. Caller's tab unchanged.
