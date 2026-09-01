# Prompt template

Drop optional sections. Never drop Objective, Requirements, Constraints, or Done when.

~~~markdown
# [JOB TYPE] — [short title]

You are a coding agent working in this repository. Do the job below. Do not expand scope.

## Objective
[One paragraph. Outcome when you stop. No implementation recipe.]

## Context
- Repo / service:
- Area:
- Current behavior:
- Desired behavior:
- Impact:

Relevant code (current state only):

```ts
// file: relative/path.ts
[minimal excerpt]
```

Related modules this must stay compatible with:
- `path` — why

## Requirements
1. [Testable statement]
2. [Testable statement]

## Constraints and non-goals
- Do not:
- Do not:
- Out of scope:
- Compatibility:

## Read first
- `verified/path` — [what to learn from it]
- `other/path` — [UNVERIFIED] [why it might matter]

## Edge cases
- [only real ones]

## Done when
- [exact test or command]
- [observable check]
- No unrelated files changed

## Output
- [implement, run done-when checks, list files touched and remaining risks]
~~~

## Fill rules

- Paths are real and checked, or tagged `[UNVERIFIED]`.
- A stranger can pass/fail each requirement line.
- At least two "do not" lines.
- Fences include the file path. Excerpt only.
- Investigate jobs — Done when is "answer with evidence and file citations," not a patch.
