---
name: code-security-review
description: Run code review with fixes, security review, and automatic commit
---

## Workflow

This skill orchestrates a comprehensive review pipeline:

1. **Code Review** (`/code-review <level> --fix`) - Analyze code and auto-apply fixes
2. **Security Review** (`/security-review`) - Identify security concerns
3. **Address Findings** - Fix vulnerabilities and issues identified in security review
4. **Commit** (`/git-commit`) - Stage and commit all changes with appropriate type

## Parameters

- **`level`** - Review depth: `low`, `medium`, `high`, or `xhigh`

## Execution Steps

1. If level not provided, ask the user which review depth to use
2. Run `/code-review <level> --fix`
3. Wait for completion and review the changes
4. Run `/security-review`
5. Address security findings - fix vulnerabilities and issues identified
6. Evaluate findings to determine commit type (feat, fix, refactor, security, etc.)
7. Run `/git-commit <type>` where type is based on the nature of changes

## Defaults

- Commit type: Determined by the nature of changes
  - `security` if security issues were fixed
  - `fix` if bugs were fixed
  - `refactor` if code was refactored
  - `feat` for new functionality
