# ADR Format

ADRs live in `docs/adr/` and use sequential numbering: `0001-slug.md`, `0002-slug.md`, etc.
Create the `docs/adr/` directory lazily, only when the first ADR is needed.

## Template

```md
# {Short title of the decision}

{1-3 sentences: what's the context, what did we decide, and why.}
```

That is enough for most ADRs. The value is in recording that a decision was made and why, not in filling out sections.

## Optional sections

Only include these when they add genuine value:

- Status frontmatter: `proposed | accepted | deprecated | superseded by ADR-NNNN`
- Considered Options
- Consequences

## Numbering

Scan `docs/adr/` for the highest existing number and increment by one.

## When to offer an ADR

All three of these must be true:

1. Hard to reverse.
2. Surprising without context.
3. The result of a real trade-off.

Qualifying examples: architectural shape, integration patterns between contexts, technology choices with lock-in, boundary and scope decisions, deliberate deviations from the obvious path, constraints not visible in code, and non-obvious rejected alternatives.
