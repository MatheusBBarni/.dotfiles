---
name: grill-and-create-tasks
description: Grill a PRD/tech spec plan deeply, then generate or update executable tasks via cy-create-tasks. Use when a user has a PRD + tech-spec and wants a rigorously reviewed plan converted into task files in the provided feature-task-dir.
---

# Grill and Create Tasks

## Purpose

Combine the grilling workflow with task decomposition:

1. resolve ambiguity and dependencies in the plan using grill-me discipline,
2. generate or update task artifacts with cy-create-tasks.

## Invocation

```bash
$grill-and-create-tasks <prd-path> <techspec-path> <feature-task-dir>
```

- `prd-path`: path to PRD markdown
- `techspec-path`: path to TechSpec markdown
- `feature-task-dir`: path where task files will be written (typically `.compozy/tasks/<feature>/`).

## Required setup

- The target task directory must exist or be creatable.
- Copy provided docs into the task directory only if missing and clearly referenced by the user.
- If `<feature-task-dir>` lacks `_prd.md` and `_techspec.md`, explain the gap and continue with the best available source (PRD- or TechSpec-first per available files).

## Workflow

1. Validate argument paths exist and are files/directories.
2. Read PRD and TechSpec and note unresolved assumptions, dependencies, and unknowns.
3. Run one-question-at-a-time grilling:
   - ask one high-leverage question,
   - include a recommended answer,
   - include tradeoff and risk,
   - continue until the plan is internally consistent.
4. Confirm with the user before task generation.
5. Prepare the task directory and call workflow logic equivalent to `cy-create-tasks` for that feature:
   - load task types,
   - decompose into independently implementable tasks,
   - request user approval on breakdown,
   - generate `_tasks.md` + `task_01.md...` files in `<feature-task-dir>`,
   - run validation command workflow and report failures.

## Success criteria

- All required inputs are acknowledged before decomposition.
- No major or hidden assumptions remain unchallenged.
- Task files include dependencies, complexity, test requirements, and implementation context.
- Task artifacts are ready for `compozy tasks validate --name <feature>`.
