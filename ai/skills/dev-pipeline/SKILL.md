---
name: dev-pipeline
description: 'Orchestrates a TDD-focused development pipeline: requirements clarification (grill-me), test-first implementation via /tdd (red-green-refactor vertical slices), code review, and remediation of review findings. Use when the user asks to implement a feature with TDD, mentions "pipeline", "dev pipeline", "test-first", or wants the full development flow. Accepts any combination of PRD, Figma link, and Jira issue as optional inputs — at least a task description is needed. The output of each step becomes the input of the next.'
---

# Dev Pipeline (TDD)

Orchestrates a test-driven development pipeline. Requirements first, then tests before code — one behavior at a time.

## Inputs (all optional, combinable)

| Input          | How to provide                           | What it contributes                                   |
| -------------- | ---------------------------------------- | ----------------------------------------------------- |
| **PRD**        | Upload file or paste text                | Feature scope, requirements, acceptance criteria      |
| **Figma link** | Paste URL                                | UI/UX specs, component layout, design decisions       |
| **Jira issue** | Paste issue key (e.g. `PROJ-123`) or URL | Task description, acceptance criteria, linked context |

At least one input or a plain task description is required. All three can be provided together — the skill merges them into a unified context before running grill-me.

## Flow

```
[PRD] + [Figma Link] + [Jira Issue] + [Task Description]
                       ↓
              0. Input Collection  → fetch & merge all sources
                       ↓
              1. grill-me          → fill gaps not covered by inputs
                       ↓
              1.5 Save Requirements → .specs/<generated_name>/plan.md
                       ↓
              2. /tdd Planning     → confirm interface + behaviors to test
                       ↓
              2.5 Save TDD Plan    → .specs/<generated_name>/implementation-plan.md
                       ↓
         ┌──── 3. TDD Loop (vertical slices) ────┐
         │  3a. RED   → qa-engineer writes ONE test (fails)
         │  3b. /git-commit (test)
         │  3c. GREEN → the-engineer writes code to pass test + meet requirements
         │       ↳ if blocked → STOP and report to operator (user)
         │  3d. /git-commit (feat)
         │  repeat until all prioritized behaviors are covered
         └─────────────────────────────────────────┘
                       ↓
              4. /tdd Refactor   → the-engineer cleans up (tests stay green)
                       ↓
              4.5. /git-commit (refactor, if changes made)
                       ↓
              5. Reviewer Agent  → review code + tests
                       ↓
              6. Remediation     → the-engineer addresses reviewer findings
                       ↳ if blocked → STOP and report to operator (user)
                       ↓
              6.5. /git-commit (fix/refactor, if changes made)
```

## Execution Instructions

### STEP 0 — Input Collection & Merging

Before running grill-me, collect and parse all provided inputs.

**PRD (if provided):**

- Read and parse the full document
- Extract: objective, expected behavior, edge cases, stack, constraints

**Figma link (if provided):**

- Fetch the Figma link using available tools (MCP or web fetch)
- Extract: screen/component names, layout descriptions, interaction notes, design tokens if visible
- If the link is not accessible, note it and ask the user to paste the relevant Figma specs manually

**Jira issue (if provided):**

- Use the Atlassian MCP tool to fetch the issue by key or URL
- Extract: summary, description, acceptance criteria, linked issues, assignee, labels
- If Jira is not connected, ask the user to paste the issue content manually

**Merge all sources into a single Raw Context document:**

```
## Raw Context

### From PRD

<extracted content>

### From Figma

<extracted content or "not provided">

### From Jira

<extracted content or "not provided">

### Additional task description

<user's plain text, if any>
```

> ⚠️ If none of the above were provided and there is no task description, ask the user for at least one input before continuing.

---

### STEP 1 — grill-me (Requirements Clarification)

Read the `grill-me` skill and execute it using the `Raw Context` from Step 0 as the base.

- Present a summary of what was already extracted from the inputs
- Run grill-me **only to fill gaps** — do not ask about things already covered by the inputs
- Typical gaps to check for:
  - Missing stack or technology decisions
  - Unclear acceptance criteria
  - Unaddressed edge cases
  - Ambiguous UI behavior not covered by Figma
  - Dependencies or constraints not mentioned in Jira/PRD
- **Wait for the user's answers** before continuing
- Consolidate everything into a **Requirements Document** containing:
  - Feature objective
  - Expected behavior
  - Identified edge cases
  - Stack / technologies involved
  - UI/UX references (from Figma, if provided)
  - Constraints or dependencies

> ⚠️ Do not advance to Step 1.5 / Step 2 without an approved Requirements Document.

---

### STEP 1.5 — Persist Requirements Document

After the Requirements Document is approved, save it under `.specs/<generated_name>/` before planning:

1. **Generate a name** (`<generated_name>`):
   - Prefer Jira issue key + short feature slug when available (e.g. `DST-4193-consumption-alert-crud`)
   - Otherwise kebab-case from the feature objective (e.g. `user-checkout-valid-cart`)
   - Lowercase ASCII only; hyphen-separated; strip punctuation and collapse spaces
   - If `.specs/<generated_name>/` already exists, append `-2`, `-3`, etc. until unique
2. **Ensure** `.specs/<generated_name>/` exists (create directories if missing)
3. **Write** the approved Requirements Document to `.specs/<generated_name>/plan.md`
4. **Tell the user** the saved path
5. **Treat that file as canonical** for later steps — when requirements change (e.g. GREEN escalation clarifying requirements), update the same file on disk

> ⚠️ Do not advance to Step 2 until the Requirements Document is written to `.specs/<generated_name>/plan.md`.

---

### STEP 2 — /tdd Planning

Read the `tdd` skill and execute its **Planning** phase using the Requirements Document from Step 1 (canonical path: `.specs/<generated_name>/plan.md`).

Before any test or production code is written:

- [ ] Explore the codebase; read `CONTEXT.md` if it exists
- [ ] Confirm with the user what public interface changes are needed
- [ ] Confirm which behaviors to test (prioritized — not every edge case)
- [ ] Identify deep-module opportunities (small interface, deep implementation)
- [ ] List behaviors as observable outcomes, not implementation steps
- [ ] Order behaviors for vertical slices (tracer bullet first, then incremental)
- [ ] **Wait for user approval** on the TDD plan

Produce a **TDD Plan** containing:

```
## TDD Plan

### Public interface
<functions, components, APIs to expose>

### Behaviors to test (in order)
1. <first tracer-bullet behavior>
2. <next behavior>
...

### Out of scope for this cycle
<behaviors explicitly deferred>
```

> ⚠️ Do not advance to Step 2.5 / Step 3 without an approved TDD Plan.
> ⚠️ Do NOT write all tests upfront. The plan lists behaviors; each slice writes ONE test at a time.

---

### STEP 2.5 — Persist Implementation Plan

After the TDD Plan is approved, save it under the same `.specs/<generated_name>/` directory:

1. **Write** the approved TDD Plan to `.specs/<generated_name>/implementation-plan.md`
2. **Tell the user** the saved path
3. **Treat that file as canonical** for later steps — when the plan changes mid-pipeline, update the same file on disk

> ⚠️ Do not advance to Step 3 until the TDD Plan is written to `.specs/<generated_name>/implementation-plan.md`.

---

### STEP 3 — TDD Loop (Vertical Slices)

Read the `tdd` skill and execute **Tracer Bullet** + **Incremental Loop** for each behavior in the TDD Plan (canonical path: `.specs/<generated_name>/implementation-plan.md`).

**Anti-pattern to avoid:** writing all tests first, then all implementation (horizontal slicing). Each cycle is RED → GREEN for ONE behavior only.

For each behavior in the TDD Plan (starting with the tracer bullet):

#### 3a. RED — Write failing test

Invoke **qa-engineer** with `/tdd`:

```
Task: /tdd
Write ONE failing test for this behavior: <current behavior from TDD Plan>
Requirements: <Requirements Document from Step 1>
TDD Plan: <full TDD Plan from Step 2>
Slice: <N of M>
Figma reference: <if available>

Rules:
- Test describes observable behavior through public interface only
- Test must fail because implementation does not exist yet
- Do NOT write production code
- Do NOT write tests for future behaviors
```

**Collect:** test file(s), confirmation test fails (RED).

#### 3b. Git Commit (RED)

Invoke the **git-commit** skill:

- Type: `test`
- Message should name the behavior being tested (e.g., `test: add failing test for user checkout with valid cart`)

> ⚠️ Do not advance to GREEN until the RED commit is confirmed.

#### 3c. GREEN — Implementation (must pass test AND meet requirements)

Invoke **the-engineer** with `/tdd`:

```
Task: /tdd
Make this test pass with correct, minimal code: <test from 3a>
Requirements Document (grill-me): <full Requirements Document from Step 1>
TDD Plan: <full TDD Plan from Step 2>
Figma reference: <if available>

Rules:
- The implementation MUST make the current test pass (GREEN)
- The implementation MUST comply with the Requirements Document from grill-me — not just satisfy the test in isolation
- Write only enough code to pass the current test while honoring requirements
- No speculative features for future behaviors
- Do NOT refactor yet
- Do NOT weaken, skip, or delete the test to force a pass
- Do NOT work around requirements — if the test and requirements conflict, stop and escalate (see below)
- Run the test after implementation and confirm it passes before returning

Success criteria (all must be true):
- [ ] The failing test from 3a now passes
- [ ] The code aligns with the Requirements Document (behavior, stack, constraints)
- [ ] No unrelated production code was added
```

**Collect:** implementation file(s), test run output confirming GREEN.

#### 3c.1 — Escalation when GREEN is blocked

If **the-engineer** cannot write proper code that passes the test while complying with the Requirements Document, **STOP the pipeline immediately**. Do not advance to 3d, do not start the next slice, and do not commit partial or incorrect code.

Present the operator (user) with a **GREEN Blocker Report**:

```
## 🛑 GREEN Blocked — Operator Action Required

### Slice
<behavior N of M — name>

### Test
<file and test name that still fails or cannot be satisfied>

### What was attempted
<brief summary of implementation approaches tried>

### Why it cannot proceed
<specific blocker — pick all that apply>
- Test is incorrect or untestable as written
- Requirements Document conflicts with the test
- Missing dependency, access, or infrastructure
- Stack/constraint from grill-me makes implementation impossible
- Ambiguity in requirements — multiple valid interpretations

### Evidence
<test output, error messages, or concrete mismatch with requirements>

### Recommended resolution
<what the operator should decide or provide — e.g. fix test, clarify requirement, add dependency>
```

**Wait for operator guidance** before resuming. Depending on the resolution:

- **Fix the test** → return to 3a (RED) for this slice
- **Clarify requirements** → update Requirements Document and `.specs/<generated_name>/plan.md`, then retry 3c
- **Unblock dependency** → operator resolves, then retry 3c

> ⚠️ Never silently skip a blocked slice. Never commit failing code as GREEN.

#### 3d. Git Commit (GREEN)

Invoke the **git-commit** skill:

- Type: `feat`
- Message should name the behavior implemented (e.g., `feat: implement checkout for valid cart`)

> ⚠️ Do not start the next slice until the GREEN commit is confirmed.

**Repeat 3a–3d** until all prioritized behaviors in the TDD Plan are covered.

Consolidate all slices into:

- **Test Package** — all test files and coverage summary
- **Code Package** — all implementation files and technical decisions

---

### STEP 4 — /tdd Refactor

After all behaviors are GREEN, invoke **the-engineer** with `/tdd` refactor checklist:

```
Task: /tdd
Refactor the implementation while keeping all tests green.
Requirements: <Requirements Document from Step 1>
Tests: <Test Package>
Code: <Code Package>

Refactor checklist:
- [ ] Extract duplication
- [ ] Deepen modules (complexity behind simple interfaces)
- [ ] Apply SOLID where natural
- [ ] Run tests after each refactor step
- [ ] Never change behavior — tests must stay green
```

**Collect:** refactored code, confirmation all tests still pass.

---

### STEP 4.5 — Git Commit (Refactor, if needed)

If Step 4 produced changes, invoke the **git-commit** skill:

- Type: `refactor`
- Message summarizing what was cleaned up

If no refactor changes were made, skip this step and note it in the final report.

---

### STEP 5 — Reviewer Agent

Invoke **code-reviewer**, passing code, tests, and Jira context against the core requirements.

```
Task: Review the implementation against the requirements below.
Requirements Document: <Requirements Document from Step 1>
TDD Plan: <TDD Plan from Step 2>
Code: <Code Package from Step 3>
Tests: <Test Package from Step 3>
Jira issue: <Jira content from Step 0, if available>
```

**What to collect:**

- Issues found (bugs, code smells, pattern violations)
- Improvement suggestions
- TDD quality: do tests verify behavior through public interfaces?
- Approval or list of blockers

Consolidate into a **Review Report**.

> If the reviewer reports **approved with no blockers or required changes**, skip Step 6 and go directly to Final Output.

---

### STEP 6 — Remediation (Address Review Findings)

If the Review Report contains blockers, bugs, or required changes, invoke **the-engineer**:

```
Task: Address all reviewer findings and required changes.
Review Report: <full Review Report from Step 5>
Requirements Document (grill-me): <full Requirements Document from Step 1>
TDD Plan: <TDD Plan from Step 2>
Code: <Code Package from Step 3/4>
Tests: <Test Package from Step 3>

Rules:
- Fix every blocker and required change from the Review Report
- Do NOT introduce behavior outside the Requirements Document
- Do NOT weaken, skip, or delete tests to force a pass
- Run the full test suite after each fix and confirm all tests stay green
- Preserve TDD quality — tests must still verify behavior through public interfaces

Success criteria (all must be true):
- [ ] Every blocker and required change from the Review Report is resolved
- [ ] All tests pass
- [ ] Code still complies with the Requirements Document
```

**Collect:** updated code, list of findings addressed, test run output.

#### 6.1 — Escalation when remediation is blocked

If **the-engineer** cannot resolve a reviewer finding without breaking tests, violating requirements, or making an unsafe change, **STOP the pipeline immediately**. Do not commit partial fixes.

Present the operator (user) with a **Remediation Blocker Report**:

```
## 🛑 Remediation Blocked — Operator Action Required

### Finding
<reviewer issue that could not be resolved>

### What was attempted
<brief summary of fix approaches tried>

### Why it cannot proceed
<specific blocker — e.g. finding conflicts with requirements, fix requires architectural change, test gap, missing context>

### Evidence
<test failures, errors, or trade-off explanation>

### Recommended resolution
<what the operator should decide — e.g. accept trade-off, update requirements, defer finding, provide more context>
```

**Wait for operator guidance** before resuming.

> ⚠️ Never silently skip unresolved reviewer findings.

---

### STEP 6.5 — Git Commit (Remediation, if needed)

If Step 6 produced changes, invoke the **git-commit** skill:

- Type: `fix` for bugs/blockers, or `refactor` for code-quality findings
- Message should reference what was addressed (e.g., `fix: address reviewer findings for checkout validation`)

If no remediation changes were made (reviewer approved with no blockers), skip this step and note it in the final report.

> ⚠️ Do not present Final Output until Step 6 is complete or explicitly skipped (approved with no findings).

---

### Final Output

After Step 6 (or Step 5 if reviewer approved with no findings), present the user with a **Pipeline Report**:

```
## ✅ TDD Pipeline Complete

### 📥 Inputs Used
<list which inputs were provided: PRD / Figma / Jira / task description>

### 📄 Spec Paths
- Requirements: `.specs/<generated_name>/plan.md`
- Implementation plan: `.specs/<generated_name>/implementation-plan.md`

### 📋 Confirmed Requirements
<summary of the requirements document>

### 🎯 TDD Plan
<behaviors tested, in order — from implementation-plan.md>

### 🔄 TDD Slices
<for each slice: behavior → test file → implementation file → commits>
<if any slice was blocked: include GREEN Blocker Report and resolution>

### 🧪 Test Package
<test files and coverage>

### 💻 Code Package
<files and key technical decisions>

### 🔍 Review
<issues found and status: approved / requires changes>

### 🔧 Remediation
<findings addressed by the-engineer, or "skipped — reviewer approved with no blockers">
<if blocked: include Remediation Blocker Report and resolution>

### 🚀 Next Steps
<any remaining unresolved items or deferred findings>
```

---

## Important Rules

1. **Never skip steps** — each step depends on the output of the previous one
2. **Preserve context** — always pass complete documents between steps, not summaries
3. **Steps 1 and 2 are blocking** — only advance after the user responds and approves
4. **Persist specs under `.specs/<generated_name>/`** — `plan.md` after requirements approval (Step 1.5), `implementation-plan.md` after TDD plan approval (Step 2.5); keep both updated if they change mid-pipeline
5. **Inputs are additive** — more inputs = fewer grill-me questions, never duplicate effort
6. **Tests before code** — never write production code before the failing test for that behavior exists
7. **Vertical slices only** — one RED → one GREEN per behavior; never bulk-write all tests then all code
8. **Read the `tdd` skill** at Steps 2, 3, and 4 — follow its philosophy, anti-patterns, and checklists
9. **If an input source is inaccessible** (Figma blocked, Jira not connected), note it and ask the user to provide the content manually
10. **If an agent returns something incomplete**, record it in the final report and flag it to the user
11. **Git commits in Step 3 are blocking** — commit after each RED and each GREEN before advancing; do not skip commits even if output seems partial
12. **GREEN must satisfy both test and grill-me** — the-engineer writes code to pass the test AND comply with the Requirements Document; passing the test alone is not enough
13. **Stop and escalate on GREEN failure** — if the-engineer cannot produce proper passing code, halt the pipeline, report to the operator with a GREEN Blocker Report, and wait for guidance; never skip, weaken tests, or commit failing code
14. **Always remediate review findings** — after the reviewer, invoke the-engineer to address all blockers and required changes; only skip Step 6 when the reviewer explicitly approves with no findings
15. **Stop and escalate on remediation failure** — if the-engineer cannot resolve a reviewer finding safely, halt and report to the operator with a Remediation Blocker Report; never commit partial or broken fixes
