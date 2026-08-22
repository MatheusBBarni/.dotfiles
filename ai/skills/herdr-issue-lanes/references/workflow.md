# Manual launch sequence

Use only if `scripts/launch_issue_lanes.py` cannot run. Parse IDs from JSON. Keep `--no-focus`.

## 1. Resolve each issue

```bash
gh issue view <N> --json number,title,url,labels
```

Branch: `<feat|fix>/issue-<N>`. Tab label: `#<N>`. Agent name: `issue-<N>`.
Default first prompt: the issue `url`.

## 2. Create the worktree, drop the extra workspace

`herdr worktree create` opens a **new workspace**. Close it. Keep the checkout.

```bash
herdr worktree create \
  --workspace "$HERDR_WORKSPACE_ID" \
  --branch fix/issue-26 \
  --base origin/main \
  --label "#26" \
  --no-focus
# read .result.worktree.path and .result.workspace.workspace_id
herdr workspace close <new-workspace-id>
```

If the branch/path already exists, skip create and use `herdr worktree list --cwd "$PWD"` to get the path.

## 3. Open a tab in the caller workspace

```bash
herdr tab create \
  --workspace "$HERDR_WORKSPACE_ID" \
  --cwd <worktree-path> \
  --label "#26" \
  --no-focus
# read .result.tab.tab_id and .result.root_pane.pane_id
```

## 4. Start the agent and send the first prompt

The pane must be an idle shell (tab create leaves it that way).

```bash
herdr agent start issue-26 --kind pi --pane <pane-id> --timeout 60000 -- <agent-args...>
herdr agent prompt issue-26 "https://github.com/<owner>/<repo>/issues/26"
```

Do not pass `--wait`. Confirm with `herdr agent read issue-26 --source recent-unwrapped --lines 40`.

## 5. Repeat in the user's issue order

Preserve the order the user listed. Leave the calling tab focused.

## Failure notes

- `HERDR_ENV` unset: stop. Do not drive Herdr from outside.
- Worktree create succeeded but tab create failed: leave the checkout; do not `worktree remove` unless the user asks.
- `agent start` timeout: `herdr agent read <pane>` and inspect the shell before retrying.
- `agent_prompt_stalled` / still idle: read the pane; resend only if the prompt text is missing.
