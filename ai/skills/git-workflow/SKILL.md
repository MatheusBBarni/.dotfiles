---
name: git-workflow
description: "Run an end-to-end GitHub delivery workflow for a local branch: use $git-commit with a required conventional commit type, push the branch, open a pull request, inspect and review it, address actionable comments, commit and push fixes if needed, merge the PR, and close a specified issue. Use when the user asks to publish/ship/merge current repo work through PR review and issue closure, especially with inputs like commit type and issue number."
---

# Git Workflow

## Inputs

- `type` is required: pass it to `$git-commit`. Valid values are the conventional commit types accepted by that skill: `feat`, `fix`, `chore`, `refactor`, `docs`, `style`, `test`, `perf`, `ci`, `build`, `revert`.
- `issue` is required for the final closure step: a GitHub issue number or URL.
- Optional PR title/body context may be used when opening the PR.

If either `type` or `issue` is missing, ask for only the missing value before changing GitHub state.

## Preconditions

- Work from the repository root.
- Confirm the current branch is not a protected trunk branch such as `main` or `master`. If it is, ask whether to create or switch to a feature branch before committing.
- Inspect `git status --short` before starting.
- Never include secrets, token values, `.env` contents, or webhook URLs in commits, PR text, comments, or logs.
- Never force-push.

## Workflow

1. Use `$git-commit` with the user-provided `type`.
   - Let `$git-commit` stage, inspect, and commit changes.
   - Do not run `git commit` manually.
   - If `$git-commit` reports no changes, continue only if the branch already contains commits that need a PR.

2. Push the current branch.
   - Use `git push -u origin HEAD` for the first push.
   - Use plain `git push` after the upstream exists.
   - Do not force-push.

3. Open a pull request.
   - Prefer GitHub tooling available in the session, such as the GitHub app/plugin or `gh`.
   - Base the PR on the repository default branch unless the user specified another base.
   - Include a concise summary, verification performed, and `Closes #<issue>` only if closing on merge is intended. If the user explicitly wants issue closure after merge, it is acceptable to omit auto-close text and close manually in the final step.

4. Review the PR.
   - Inspect the PR diff, changed files, and checks.
   - Look for correctness, regressions, missing verification, accidental generated files, secrets, and unrelated changes.
   - Inspect PR review comments and unresolved threads.
   - If CI/checks are failing, debug them before merge.

5. Address actionable comments.
   - Implement fixes for comments that are clearly actionable.
   - If a comment is ambiguous, conflicts with the user’s instructions, or requires product judgment, ask the user.
   - Re-run the relevant verification after edits.

6. Commit and push fixes if needed.
   - If comment remediation changed files, use `$git-commit` again with the same `type` unless the user gave another type.
   - Push without force.

7. Merge the PR.
   - Merge only after review comments are addressed or explicitly deferred and required checks are passing or intentionally waived by the user.
   - Use the repository’s normal merge strategy. If the correct strategy is unclear, prefer the repo default exposed by GitHub tooling.

8. Close the issue.
   - Close the issue parameter provided by the user if it is still open.
   - Add a short closing note referencing the merged PR when the tool supports it.

## Reporting

Finish with:

- Commit hash(es) and messages.
- Branch name and PR URL.
- Review/comment remediation summary.
- Verification commands and results.
- Merge result.
- Issue closure result.
