---
name: grill-techspec
description: Runs a focused grilling session that turns an idea, plan, draft RFC, or architecture proposal into a rigorous technical specification. Use when the user asks to be grilled on a tech spec, stress-test a technical design, resolve architecture decisions before writing a spec, or refine an existing technical specification through one-question-at-a-time interrogation.
---

# Grill Tech Spec

## Quick start

When invoked:
1. Load or consult the `grill-me` and `technical-specification` skills if available.
   - Check local skill dirs first: `.agents/skills`, `.codex/skills`, `.pi/agent/skills`, and `projects/.dotfiles/ai/skills`.
2. Ask for or infer the target: new spec, existing spec file, or rough idea.
3. Read provided files and inspect the codebase for answers before asking.
4. Summarize current understanding in 3-6 bullets.
5. Ask the single highest-leverage unresolved question, with your recommended answer.
6. Continue until enough decisions are captured, then draft or update the tech spec.

Do not dump a questionnaire. Grill one decision at a time.
## Composition rules

- From `grill-me`: ask exactly one question at a time, be relentless, include your recommended answer, and explore the codebase instead of asking questions the repo can answer.
- From `technical-specification`: the final artifact must be a technical spec with requirements, architecture, contracts, risks, rollout, testing, and acceptance criteria.

## Grilling loop

For each user answer:
1. Incorporate the answer into a decision log.
2. Identify dependencies that answer unlocks or blocks.
3. Challenge contradictions with the codebase, requirements, or earlier decisions.
4. Ask the next highest-leverage question.

Use this question format:

```md
Decision needed: ...
Why it matters: ...
Recommended answer: ...
Tradeoff: ...
Question: ...
```

## Required coverage

Do not finalize until each area is resolved or explicitly marked open:

- Problem, users, goals, non-goals, and success metrics.
- Scope, assumptions, and constraints.
- Existing architecture and integration points.
- Proposed architecture, components, and data flow.
- API, events, schema, storage, and migration contracts.
- Security, privacy, permissions, and abuse cases.
- Performance, reliability, scalability, and failure modes.
- Observability, analytics, and operations.
- Rollout, backwards compatibility, migration, and feature flags.
- Testing strategy and acceptance criteria.
- Alternatives rejected, risks, and open questions.

## Research before asking

If a question can be answered from repository files or docs:
- Read relevant files first.
- Cite paths in the conversation.
- Ask only to confirm ambiguous intent or choose among tradeoffs.

## Spec output

When drafting, use this structure:

```md
# Technical Specification: <name>
Status:
Date:

## Executive Summary
## Background / Context
## Goals
## Non-Goals
## Requirements
## Proposed Design
## Architecture / Components
## Data Model and Contracts
## APIs / Events
## Security and Privacy
## Performance and Reliability
## Observability
## Migration and Rollout
## Testing Strategy
## Alternatives Considered
## Risks and Mitigations
## Open Questions
## Acceptance Criteria
```

If an output path exists, edit the file. If no path is given, produce Markdown in the response.

## Stop conditions

Stop grilling only when the user says to draft, all required coverage is resolved, or a blocking product decision cannot be answered. If blocked, draft with open questions clearly marked instead of pretending certainty.
