---
name: git-worktree
description: Create Git worktrees from the current repository in the standard local layout. Use when the user asks to create, prepare, open, or set up a git worktree from the repo Codex is currently in, especially with the convention ~/projects/worktree/{half-uuid}/{original-repo-folder}.
---

# Git Worktree

Create a Git worktree from the current repository under:

```text
~/projects/worktree/{half-uuid}/{original-repo-folder}
```

For example, from `~/projects/pokemeta-tracker`, create:

```text
~/projects/worktree/abcd1234-ef56-7890/pokemeta-tracker
```

## Workflow

1. Confirm the current directory is inside a Git repository:

```bash
git rev-parse --show-toplevel
```

2. Use the bundled script from the skill directory:

```bash
bash ~/.codex/skills/git-worktree/scripts/create_worktree.sh
```

3. If the user provides a branch name, create a branch in the new worktree:

```bash
bash ~/.codex/skills/git-worktree/scripts/create_worktree.sh --branch feature/my-task
```

4. If the user provides a base ref, pass it explicitly:

```bash
bash ~/.codex/skills/git-worktree/scripts/create_worktree.sh --branch feature/my-task --base origin/main
```

5. Report the created path and the command to enter it.

## Behavior

- Default mode creates a detached worktree at `HEAD`, avoiding conflicts with the currently checked-out branch.
- `--branch <name>` creates a new branch in the new worktree.
- `--base <ref>` chooses the commit/ref to check out; default is `HEAD`.
- `WORKTREE_ROOT` can override the root folder, but default to `~/projects/worktree`.
- The script prints the final path as `WORKTREE_PATH=...`; use that in the final response.

## Safety

- Do not delete existing worktrees unless the user explicitly asks.
- Do not run destructive Git commands.
- If `git worktree add` fails because the branch already exists, explain the conflict and suggest either a new branch name or `--detach`.
