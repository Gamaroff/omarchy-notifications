---
title: Documentation Conventions
type: guide
status: active
created: 2026-10-14
updated: 2026-10-14
source: "rebirth-wallet/docs/development/documentation-conventions.md and docs/development/cross-referencing-standards.md, with generic parts of tinker-city/docs/development/documentation-conventions.md (adapted 2026-10-14)"
---

# Documentation Conventions

The generic rules for how documentation is named, structured and linked in every repo that
references this guide. A repo's own `AGENTS.md` may add rules or name the checks that enforce them.

**The governing principle:** a rule earns its place when something breaks when it is violated: a
pipeline that halts, a sync that silently skips, a generated file that goes stale, a check that
fails. **A rule with no consumer and no gate is a preference.** The same principle, applied to
prompts, is in [prompt iteration standards](prompt-iteration-standards.md).

---

## File naming

**Dots separate structural components; hyphens separate words inside a descriptive name.**
Lowercase throughout, `.md` extension.

```
epic.12.account-security.md           correct
story.12.1.encryption-service.md      correct
task.38.status-vocabulary-check.md    correct

epic_12_account_security.md           wrong: underscores
epic-12-account-security.md           wrong: hyphens as structural separators
Epic.12.AccountSecurity.md            wrong: capitalisation
```

- No dots inside the `{name}` segment. A name like `discovery-2.0` breaks `epic.{N}.{name}` parsers.
- Companion files reuse the work item's name slug exactly.

## Work-item directories and companion files

Every epic, story and task lives in **its own self-named directory**. The main document is
named after the directory. Companion artifacts share the base name with a type segment inserted:

```
story.5.1.demo-foundation/
├── story.5.1.demo-foundation.md
├── story.5.1.plan.1.demo-foundation.md
├── story.5.1.review.1.demo-foundation.md
├── story.5.1.implementation.1.demo-foundation.md
├── story.5.1.qa.1.demo-foundation.md
├── story.5.1.gate.1.demo-foundation.yml
└── story.5.1.dod.1.demo-foundation.md
```

Type segments: `.plan.` · `.review.` · `.qa.` · `.gate.` · `.dod.` · `.implementation.` · `.bug.`

Companions have their **own** lifecycle and their own `status` values. They are not the work item.
A glob like `task.*.md` sweeps them in with the main document and gives a wrong count. **Exclude
companions before counting anything.**

## Status vocabulary for stories and tasks

The agent-skills pipelines accept exactly these frontmatter values. The authoritative list is
`.agents/skills/finalise/references/document-status-lifecycle.md` in each repo; this table matches
it. Other documents are outside this enum: guides carry `status: active`, and ADRs record their state
in their own `## Status` section ([ADR conventions](../architecture/adr-conventions.md)).

| Frontmatter `status:` | Body `Status:` | Set by |
| --- | --- | --- |
| `draft` | Draft | `create-story`, `create-task` |
| `planned` | Planned | `create-task` (tasks only) |
| `ready-for-development` | Ready for Development | `review-story`, `review-task` |
| `in-progress` | In Progress | `develop` |
| `ready-for-review` | Ready for Review | `develop` (on completion) |
| `accepted` | Accepted | `finalise` (DoD passed, QA gate PASS or WAIVED) |
| `cancelled` | Cancelled | any skill or human |

Lifecycle: `draft → planned → ready-for-development → in-progress → ready-for-review → accepted`.
`cancelled` is reachable from any non-terminal state. `accepted` and `cancelled` are terminal. The
QA loop adds one backward edge: `ready-for-review → in-progress`.

- **Frontmatter is lowercase kebab-case. The body line is Title Case.** Change both in the same edit.
  `finalise` fails the DoD if they disagree.
- **Do not use the deprecated synonyms:** `Ready for QA`, `ready-for-dev`, `Completed`,
  `Ready for Done`. Their replacements are `ready-for-review`, `ready-for-development`, `accepted`
  and `ready-for-review` (not `accepted`).
- **`superseded` is not a valid status.** Use `cancelled`, and record the supersession in the
  Change Log.
- **Tracker status names are never written into local frontmatter.** Direction of travel is local
  to tracker, always.

## No emoji in frontmatter

Emoji are fine in body prose: checklists, status tables, progress notes. They are never a
frontmatter value. A status is machine-readable; `📋 Planned` matches no enum anywhere.

## Change Log

Every epic, story and task carries a `## Change Log` section. The header is exactly four columns:

```
| Date | Version | Description | Author |
```

- **Append-only.** Add rows; never rewrite earlier ones.
- Post-acceptance edits to a document get a Change Log row.
- When converting a legacy 2-column log (`| Date | Change |`), add the `Version` and `Author`
  columns and backfill `—` for historical rows. **Do not invent versions or authors.** Recover real
  values from `git log` / `git show` where the original row survives in history; that is evidence,
  a guess is not.

## No committed PROGRESS files

Progress belongs in the work item's own Change Log and status field, not a parallel file that
drifts. Scratch or checkpoint files (`PROGRESS*.md`, `REVIEW-PROGRESS*.md`) are deleted in the
same commit that completes their work. They never live inside work-item directories.

## Dated claims

**An assertion about what CI runs, verifies or enforces carries the date it became true and the
work item that made it so.**

```markdown
CI runs lint, test and build (since 2026-08-26, story 4.3).
```

This does not stop the claim going stale. It makes the staleness legible: a dated claim invites a
reader who knows the pipeline changed to distrust it, where an undated one invites belief. A stale
claim about what CI verifies is worse than most stale facts, because it tells a reader to discount
a signal that is real.

It applies to guides, architecture notes, Dev Notes and roadmap banners. It does not apply to
companion documents (`.review.`, `.qa.`, `.dod.`, `.implementation.`, `.plan.`), which are dated
by nature and are correct as history.

## Links must resolve to tracked files

Every markdown link that points inside the repo must resolve to a file **git tracks**. The oracle
is `git ls-files`, not the working tree: a link into gitignored or untracked state resolves on the
author's machine and is broken in every other checkout.

- **Never link into `.claude/`** or any other gitignored or untracked path. State the path in
  backticks instead of linking it.
- **Moving a file is a link-rewriting job.** Repoint every inbound link in the same change.
- **Write elided URLs as real ones.** A link whose target is written as `…/issues/98` renders as a
  dead link; use the full URL.
- Before calling the work done, check every new relative link resolves (`test -f`). A typo'd
  relative link fails silently.

## Cross-references are two-way

When a change touches related documents (a card, its runbook, a review or QA report, an
architecture note, a registry row, a tracker issue), each one links to the others with a real
relative path or absolute URL. A plain-text mention like "see Task 1" is not a link. This applies
to dependencies between work items too: link the specific file, don't just name it.

**When you create a companion document for an existing work item, add the link in both directions
in the same change**, not as a follow-up:

- In the work item, near its status line, link the new document.
- In the new document's opening context, link back to the work item by relative path, and to its
  tracker issue by absolute URL.

## Tables are rectangular

Every table row has the same number of cells as its header, and the header matches its delimiter
row. GFM silently **drops** the surplus cells of an over-wide row, so authored text vanishes from
the rendered page while the raw file still holds it. An under-wide row is padded, which shifts
every column after the gap. Neither is visible to a reader of the rendered page.

- **Escape pipes inside code spans.** A pipe inside backticks still splits the cell. Write
  `` `a\|b` ``. Regex alternations, union types, shell pipelines and `||` are the usual causes.
- **Do not widen a header to fit a malformed row.** Fix the row. The Change Log header is fixed at
  four columns.
- **Splitting a merged row never invents data.** Backfill `—` for any value the source does not
  contain.

---

## Related

- [Prompt iteration standards](prompt-iteration-standards.md): the same principle, applied to
  prompts and skills
- [Pipeline skills](../guides/pipeline-skills.md): the skills that write the statuses and companion files
  above
- [ADR conventions](../architecture/adr-conventions.md): naming and structure for architecture decision records
