---
title: ADR Conventions
type: guide
status: active
created: 2026-10-14
updated: 2026-10-14
source: "rebirth-wallet/docs/architecture/decisions/README.md (adapted 2026-10-14)"
---

# ADR Conventions

An Architecture Decision Record (ADR) records one significant architecture decision: the context,
the choice, and its consequences.

## Location and naming

- ADRs live in `docs/architecture/decisions/`.
- File name: `adr.NNNN.<descriptive-slug>.md`. A zero-padded sequential number and a lowercase,
  hyphenated slug. Dots separate components; hyphens separate words within the slug (see
  [documentation conventions](../development/documentation-conventions.md#file-naming)).
- Example: `adr.0007.container-registry-selection.md`.

## Immutable once accepted

An accepted ADR is not rewritten. A changed decision gets a **new ADR that supersedes the old one**
and references it. The old ADR stays in place, marked as superseded, with a link to its
replacement. The new ADR names the ADR it supersedes. Link both ways in the same change.

## Structure

Every ADR opens with `## In plain terms`, then the remaining sections in this order:

| Section | Holds |
| --- | --- |
| `## In plain terms` | 150–250 words any stakeholder can read cold: what was decided, what it means for the user, what it changes for us, what is still open and who decides it |
| `## Status` | The decision's state, and any ADR it supersedes or is superseded by |
| `## Context` | The situation and forces that made a decision necessary |
| `## Decision` | The choice made |
| `## Consequences` | What follows from the choice, good and bad |
| `## What this does not decide` | The adjacent questions left open, so the ADR is not read as settling them |
| `## Evidence` | The sources the decision rests on |

## The index

`docs/architecture/decisions/README.md` holds the index: a table with one row per ADR, linked,
with its status and any supersession. Add the row in the same change that adds the ADR, and update
both rows when one ADR supersedes another.

```markdown
| ADR | Title | Status |
| --- | --- | --- |
| [0001](adr.0001.example-slug.md) | Example decision | superseded by 0003 |
| [0003](adr.0003.replacement-slug.md) | Replacement decision | accepted; supersedes 0001 |
```

## Related

- [Documentation conventions](../development/documentation-conventions.md): file naming, links and
  cross-references that ADRs follow
