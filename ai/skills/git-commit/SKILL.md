---
name: git-commit
description: >
  Generates and runs a conventional git commit by analyzing staged changes (git diff --cached)
  and crafting a concise commit message (max 90 chars). Use this skill whenever the user wants to
  commit changes, asks to "generate a commit", "commit my changes", "create a git commit", or
  says something like "commit with type feat/fix/chore/etc". The user must provide the commit
  type (feat, fix, chore, refactor, docs, style, test, perf, ci, build, revert). The skill
  runs: git commit --no-verify -m "type: message". Always use this skill — do NOT attempt
  to run git commits manually without it.
---

# Git Commit Skill

Generates a meaningful git commit message from staged changes and executes the commit.

## Usage

The user calls this skill with:

- **type** (required): conventional commit type — one of: feat, fix, chore, refactor, docs, style, test, perf, ci, build, revert
- **extra context** (optional): any additional hints the user wants reflected in the message

## Workflow

### Step 1 — Stage all added and edited files

Run git add to automatically stage all modified, new, and deleted tracked files:

```bash
git add -u   # stages modified and deleted tracked files
git add .    # also stages new untracked files
```

If git status is completely clean before adding, stop and inform the user: **"Nenhuma alteração encontrada no repositório."**

### Step 2 — Validate there are staged changes

```bash
git diff --cached --stat
```

If still empty after the git add, stop and inform the user: **"No staged changes found after git add."**

### Step 3 — Inspect the staged diff

```bash
git diff --cached
```

Read the full diff carefully. Focus on:

- Which files changed
- What was added / removed / modified
- The intent behind the changes (not just the mechanics)

### Step 4 — Generate the commit message

Craft a message that:

- Starts with the user-provided **type** followed by `: `
- Is written in **imperative mood** ("add", "fix", "update" — not "added" or "fixes")
- Is **≤ 90 characters total** (including `type: `)
- Is **specific** — names the component, function, or area affected
- Avoids vague words like "changes", "updates", "stuff", "misc"
- Does **not** include a period at the end

**Format:** `<type>: <message>`

**Good examples:**

- `feat: add JWT refresh token rotation to auth service`
- `fix: resolve null pointer in UserRepository.findById`
- `chore: upgrade Spring Boot from 3.1 to 3.3`
- `refactor: extract payment validation into dedicated service`
- `docs: document rate limiting behavior in API README`

**Bad examples (avoid):**

- feat: changes ← too vague
- fix: fixed stuff in the user service and also updated some tests and refactored the repository layer ← too long
- chore: Updated dependencies. ← past tense + period

### Step 5 — Execute the commit

```bash
git commit --no-verify -m "<type>: <generated message>"
```

### Step 6 — Confirm to the user

Show the user:

1. The exact commit command that was run
2. The git output (commit hash + summary line)
