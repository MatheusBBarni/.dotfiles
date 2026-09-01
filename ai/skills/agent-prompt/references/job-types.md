# Job-type fields

Include only fields that apply. Do not pad.

## Bug

- Repro steps that work every time
- Full error text, stack, logs
- Current vs expected behavior
- Environment — OS, runtime, dependency versions, config that matters
- Recent changes that may have introduced it
- Current code on the failing path
- Related modules
- Existing tests and the regression test that should exist after the fix
- Who is hit and how badly

## Improvement

- How it works now, with current code
- What specifically is weak — perf, maintainability, UX, cost
- Constraints and backward-compat rules
- How success is measured
- Files that will be touched
- External libs, APIs, systems
- User impact
- Non-goals

## Feature

- Functional requirements / user stories
- Where it fits in the current system
- Integration points
- Current data shapes and what must change
- Existing APIs and any new contract
- User flow
- Edge cases
- Constraints
- External dependencies
- Tests required — unit, integration, E2E

## Investigate

- Question to answer
- Scope of search
- Evidence standard — file + line, command output
- What not to change

## Review

- Diff or PR identity
- Criteria to judge against
- Severity scale
- What not to rewrite
