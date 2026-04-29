---
name: git-ckp
description: Safely fetch, checkout/switch to, and pull a named Git branch supplied as an argument in local repositories. Use when the user asks to checkout a branch, switch branches, fetch and pull, update a branch from origin, or move the workspace onto an existing local or remote branch without losing local work.
---

# Git CKP

## Workflow

Use `scripts/checkout_pull.py` for the standard path:

```bash
python3 /home/adminai/.codex/skills/git-ckp/scripts/checkout_pull.py <branch>
```

Treat `<branch>` as the branch name supplied by the user. It can be a local branch name like `feature/login` or a remote-qualified branch like `origin/feature/login`.

Examples:

```bash
python3 /home/adminai/.codex/skills/git-ckp/scripts/checkout_pull.py main
python3 /home/adminai/.codex/skills/git-ckp/scripts/checkout_pull.py feature/my-work
python3 /home/adminai/.codex/skills/git-ckp/scripts/checkout_pull.py origin/feature/my-work
```

Pass `--remote <name>` when the branch should be fetched from a remote other than `origin`.

## Safety Rules

- Inspect local status before changing branches.
- Do not discard, reset, or overwrite user changes.
- If the worktree has local changes, stop and report the dirty files unless the user explicitly allowed carrying local changes across the checkout.
- Prefer `git switch` over legacy checkout commands.
- Pull with `--ff-only` so local history is never rewritten or merged implicitly.
- If the branch exists only as `<remote>/<branch>`, create a local tracking branch for it.
- If the requested branch does not exist locally or on the remote, report that clearly and do not create a new branch unless the user asked for branch creation.

## Manual Fallback

If the script cannot be used, run the equivalent sequence:

```bash
git status --short
git fetch --prune origin
git switch <branch>
git pull --ff-only
```

For a remote-only branch:

```bash
git fetch --prune origin
git switch --track -c <branch> origin/<branch>
git pull --ff-only
```
