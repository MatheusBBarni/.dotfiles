---
name: agent-prompt
description: Craft executable prompts for coding and tool-using agents. Use when the user wants a better agent prompt, agent brief, spec-to-prompt, rewrite this prompt, or to turn a task, bug, PRD, or ticket into a prompt for Cursor, Claude Code, Codex, or similar. Do not use for end-user copy, chat replies, or prompts that already prescribe every implementation step.
metadata:
  version: "1.1"
  type: workflow
  standalone: "true"
---

# Agent Prompt

Turn a vague task into a prompt another agent can run without guessing.

This skill is standalone. Do not load other skills to use it.

## Iron Law

```
NO PROMPT WITHOUT CONTEXT.
NO FILE PATHS WITHOUT VERIFICATION.
NO "HOW" THAT STEALS THE AGENT'S JOB.
NO AMBIGUOUS SUCCESS.
```

Give the receiving agent the WHAT — problem, current state, constraints. Do not smuggle a full solution. Make the prompt verifiable — named files, negative constraints, DONE checks. If the source is thin, interview first. Do not invent repos, APIs, or file paths.

## Output

1. One paste-ready prompt in a single fenced block
2. A **Gaps** list — unanswered or `[UNVERIFIED]` items, max 5 bullets
3. If rewriting an existing prompt, 2–4 changes that matter

Stop there unless the user asked for a rationale.

## Workflow

### 1. Classify

Pick one. Put it in the prompt title.

| Type | Goal |
|------|------|
| Bug | Reproduce, isolate, fix, prove with a test |
| Improvement | Change existing behavior under constraints |
| Feature | Add capability that fits the current system |
| Investigate | Answer with evidence. No code change unless asked |
| Review | Judge a diff against criteria. No drive-by refactors |

Per-type fields — `references/job-types.md`.

### 2. Gather context

Collect in this order:

1. Goal in one sentence
2. Current behavior vs desired behavior
3. Repo / area / files (verify paths if a workspace is available)
4. Constraints — compat, time, scope, style, security
5. Non-goals
6. Done-when signal — command, test, screenshot, or metric

Missing a critical item → ask **one** question. Prefer a short multiple-choice plus "other." Lead with a hypothesis. Stop asking once required sections can be filled without fiction.

### 3. Write

Use `references/prompt-template.md`. Required sections:

1. Role + job type
2. Objective — outcome, not method
3. Context — system as it is; only the code that shows the problem or integration point
4. Requirements — numbered, testable
5. Constraints / non-goals — what not to touch or invent
6. Read-first list — verified paths, or tagged `[UNVERIFIED]`
7. Done when — exact checks
8. Output contract — what to return

Add only if they earn tokens: repro + logs, API/data shapes, edge cases, test signatures.

Code in the prompt is evidence of current state, never a sketched fix. No sample "after" code. No prescribed algorithm.

### 4. Quality bar

Reject and rewrite if any of these hold:

- Success is "make it better", "clean it up", or "follow best practices"
- Paths are guessed and not marked `[UNVERIFIED]`
- The prompt contains the implementation the agent should invent
- Fewer than two "do not" lines
- No observable done-when check
- Context is a dump instead of the minimum that removes ambiguity
- Several shippable jobs are jammed into one prompt — split, add an order note

Tighten. Cut adjectives. Label every excerpt with path + why it is there.

## Anti-patterns

| Impulse | Do this instead |
|---------|-----------------|
| Two-line prompt | Fill the required sections |
| Paste the repo | Paste the 1–3 files that define the contract |
| "Use Clean Architecture" | Name the files and the constraint |
| "Be careful / production-ready" | Name the failure mode to avoid |
| Four features in one prompt | Four prompts plus sequence |
| Invent `src/utils/helpers.ts` | Mark `[UNVERIFIED]` or ask |

Worked rewrite — `references/examples.md`.
