---
title: Running the Pipeline Skills
type: guide
status: active
created: 2026-10-14
updated: 2026-10-14
source: "rebirth-wallet/docs/guides/pipeline-skills.md (adapted 2026-10-14)"
---

# Running the Pipeline Skills

A practical guide to the agent-skills pipelines: `/develop-next`, `/develop-story`,
`/develop-task`, `/develop-bug`, the `/qa-*` skills and `/finalise`. Repo facts (the gate
commands, the tracker, the hosting platform) are named in each repo's `AGENTS.md` and
`skills-config.yaml`.

---

## The three pipelines

`/develop-story`, `/develop-task` and `/develop-bug` are **orchestrators**. Each runs the same eight
steps by calling other skills, passing flags you would not guess and enforcing preconditions
between them.

| | `/develop-story` | `/develop-task` | `/develop-bug` |
| --- | --- | --- | --- |
| **Input** | a story document | a task document under `docs/tasks/` | an **existing** bug report |
| **Step 2** | `/review-story` | `/review-task` | `/review-bug` |
| **Step 5** | `/qa-story` | `/qa-task` | verify loop |
| **Setup questions** | 2 (base branch, PR target) | 2 (base branch, PR target) | 3 (adds bugfix off `develop` vs hotfix off `main`) |

`/develop-bug` consumes a bug report; it does not file one. That is `/create-bug-report`. General
bugs (no owning story or task) live in `docs/bugs/` with a `bug-registry.md`, where the repo has one.

## The eight steps

| # | Step | Skill invoked | Produces | Halts when |
| --- | --- | --- | --- | --- |
| 1 | Create branch | `/create-branch` | feature branch, then the pipeline lock | branch creation fails, or a lock already exists |
| 2 | Review | `/review-story` / `/review-task` / `/review-bug` | `*.review.{N}.*.md`; status → Ready for Development | review returns NEEDS REVISION, or the status did not advance |
| 3 | Develop | `/develop`, loop, `MAX_ITER=5` | code, ticked checkboxes; status → Ready for Review | an iteration ticks no box **and** makes no commit, or 5 iterations pass |
| 4 | Open PR | `/create-pr` | the PR; `pr_url` written into the lock | no base branch resolved, or the PR call fails |
| 5 | QA | `/qa-story` / `/qa-task` | `*.qa.{N}.*.md` **and** `*.gate.{N}.*.yml` | — |
| 6 | QA fix | `/qa-fix` | a fix commit, pushed; loops back to Step 5 | `/qa-fix` changes nothing, or 5 cycles pass without a clean gate |
| 7 | Finalise | `/finalise` | `*.dod.{N}.*.md`; status → `accepted` | DoD gaps, or the status is not `accepted` |
| 8 | Commit | `/commit-changes --scope <work-item-dir>` | the final report commit; lock removed | — |

The QA loop's exit gate is Step 5c, `/review-pr`, run over the open PR after the gate reads PASS or
WAIVED. The vendored `references/develop-pipeline-step-*.md` files are authoritative for each step.

**Step 4 is not the end.** A PR exists and the work looks shipped, but without Steps 5–8 there is no
gate file, no DoD, and the tracker is left in the wrong state.

**Both loops are bounded at 5.** Step 3 halts on a stall or at `MAX_ITER`. Steps 5–6 escalate after
five complete QA cycles: the report status becomes `Escalated` and the pipeline stops for a human.
Five failed cycles means the work needs a human, not a sixth attempt.

## State files

All pipeline state lives in `.claude/state/`.

| File | Written by | Meaning |
| --- | --- | --- |
| `develop-pipeline.lock` | Step 1, at its **end** | A pipeline run is in flight. One per repo, so one pipeline at a time. Carries the branch, PR URL, current step and work-item directory |
| `develop-pipeline.last-halt.json` | a halt or a pause | The halt snapshot. It lets a later run offer "resume from step N" |
| `develop-next.state.json` | `/develop-next` | Its own run state and single-flight lock (`dispatched`, `merged`, `ticked`). Deleted only when the run reports |

A crashed run leaves the lock behind, and the next pipeline halts on it. Read it before deciding
anything:

```bash
cat .claude/state/develop-pipeline.lock
cat .claude/state/develop-pipeline.last-halt.json
```

If the lock's `branch` matches no local branch, it is stale: remove it.

**Resume.** Re-invoking a pipeline on the same work item offers to resume. It reads the lock, then
verifies each step's artifact exists before trusting the implementation report's Pipeline Progress
table. The verifier will not accept a hand-written `gate.yml` for Steps 5–6 (they need the QA
report, the gate file and a PR comment), nor ticked DoD boxes for Step 7 (it needs the `*.dod.*.md`
file and `status: accepted`).

## Install the hooks

The pipelines run hands-free only with two Claude Code hooks registered: `PreCompact` for a
graceful pause, `Stop` to keep the agent from wandering off mid-run. Install once per repo; they
are shared by all pipelines and do nothing when no lock is present.

```bash
bash .agents/skills/develop-story/scripts/install-hooks.sh --dry-run   # show the settings diff
bash .agents/skills/develop-story/scripts/install-hooks.sh             # apply
```

The Stop hook re-prompting is not a bug. It fires on every mid-step yield, including while the step
waits on background subagents. Hold the step; advancing early because the hook nudged you is the
real failure.

## Lite mode

A pipeline runs `lite` only when **all three** hold: `risk_level` is `low` or absent, **and** there
are fewer than 3 tasks or phases, **and** the work touches a single module. Anything else, or any
doubt about the module boundary, is `standard`.

Lite mode changes Step 5 only: direct tools instead of parallel review agents, and Step 5c runs
`/review-pr` at low effort (degraded, never skipped). It never skips the PR, `/qa-fix`, the DoD
file, `status: accepted`, the DoD posted as a PR comment, or the tracker comment.

---

## /develop-next and the roadmap

`/develop-next` takes **one** roadmap item from "next outstanding" to "merged and ticked":

1. Selects the next unblocked item with `scripts/select-next.mjs`. Never hand-pick an item.
2. Runs its named pipeline, auto-answering the setup questions with the recommended options and
   logging each answer.
3. **Merges the green PR** (stories and tasks into `develop`), after checking the document is `accepted`, the gate has
   no open finding, the PR head matches the tested commit, CI is green where it runs, and
   `developNext.qualityGateCommand` passes on the PR branch.
4. Ticks the roadmap and adds a Change Log row, then commits and pushes on the base branch.
5. Reports, including the next eligible item.

`/develop-next --dry-run` shows what would be selected and why, and changes nothing. Wrap it in
`/loop /develop-next` for continuous runs.

When no roadmap phase holds an actionable row, the selector falls through to
`docs/bugs/bug-registry.md` and `docs/tasks/task-registry.md`, so a filed bug or task is not
invisible to the loop.

**It stops** at `manual` or `🚧` rows, `/create-*` rows (planning gaps: authoring is never run
unattended), rows with no runnable command or path, phase boundaries, any pipeline HALT, any merge
or quality-gate failure, and roadmap parse errors. A stopped run leaves its state file, so the next
invocation resumes where it stopped.

**An epic on an integration branch is only partly automated.** Its story PRs merge into the
integration branch. Nothing promotes that branch to `develop`; raise that PR by hand once every
story is in.

### The roadmap file

- Location: `docs/development/project-completion-roadmap.md` (`developNext.roadmapPath`).
- Start it from the vendored template,
  `.agents/skills/develop-next/assets/project-completion-roadmap.template.md`. `/develop-next` will
  not invent a roadmap.
- `PHASE` headings are hard boundaries. An item is eligible only when every `deps:` entry is done.
- Each row names its command (`/develop-story`, `/develop-task` or `/develop-bug`) and links its
  document.
- **Tick `[x]` only when accepted (QA PASS + DoD verified + merged) and add a Change Log row.**
- `manual` rows stop the loop. `⏭️ SKIP` rows are deferred and stepped past.

## skills-config.yaml keys every repo sets

| Key | What it is |
| --- | --- |
| `develop.fastGateCommand` | The fast gate, run every develop iteration, every qa-fix cycle and every bug verify cycle |
| `developNext.qualityGateCommand` | The full CI-equivalent gate, run on the PR branch before merge. Not every repo runs CI on PRs, so this is the real merge gate |
| `developNext.baseBranch` | `develop` |

The repo's `AGENTS.md` names the actual commands.

---

## Running a step on its own

Every step is a normal skill.

| Skill | Invoke | Needs first |
| --- | --- | --- |
| `/create-branch` | `/create-branch <doc-path>` | nothing |
| `/review-story` | `/review-story <story-path> [--validate]` | the story doc |
| `/review-task` | `/review-task <task-path>` | the task doc; interactive only, no `--validate` |
| `/develop` | `/develop <doc-path>` | **a branch already checked out**; it does not cut one |
| `/create-pr` | `/create-pr --base develop --scope <work-item-dir>` | commits to push; it commits first via `/commit-changes` |
| `/qa-story`, `/qa-task` | `/qa-story <story-path>` | **an open PR for the current branch** |
| `/qa-fix` | `/qa-fix <gate-yml-path>` | **an open PR**, plus the gate file |
| `/finalise` | `/finalise <doc-path>` | a QA report, a gate file and an approved PR |
| `/commit-changes` | `/commit-changes --scope <path>` | a dirty tree |

The traps:

- **`/qa-*` needs an open PR.** `/qa-story`, `/qa-task` and `/qa-fix` all hard-halt without one for
  the current branch. Open the PR first, even a draft.
- **`/qa-fix` takes the gate file, not the story.** The `.yml` is the authoritative list of issues.
- **`--scope` and `--exclude` differ.** `--scope` stages only those paths. `--exclude` stages the
  full tree minus those paths. This is how the pipelines keep the implementation report out of code
  commits.
- **Run `/clear` between steps** when running by hand. Each skill is a full workflow that fills the
  context window.

The whole pipeline by hand:

```bash
/create-branch  <doc-path>
/review-story   <doc-path>                     # or /review-task
/develop        <doc-path>
/create-pr      --base develop --scope <work-item-dir>
/qa-story       <doc-path>                     # or /qa-task
/qa-fix         <newest gate .yml>             # repeat QA and fix until the gate passes, max 5
/finalise       <doc-path>
/commit-changes --scope <work-item-dir>
```

`/qa-planning <story-path>` is never invoked by a pipeline. Run it yourself before coding if you
want a risk profile and test design; it needs no PR and no gate.

---

## Vendored skills are never edited in place

`.agents/skills/` is installed verbatim from `Gamaroff/agent-skills`. An edit there is lost on the
next update. To change a skill:

1. Fix it upstream in `Gamaroff/agent-skills`.
2. Re-vendor with `setup-consumer.sh --update`.
3. Commit the result as `chore(skills): …`.

Vendored `README.md` files inside the pipeline skills can lag the step references. Trust the
`references/develop-pipeline-step-*.md` files.

## Related

- [Documentation conventions](../development/documentation-conventions.md): status values, companion file names
  and the Change Log format the pipelines write
- [Prompt iteration standards](../development/prompt-iteration-standards.md): the Rule of Three for authoring
  skills; `MAX_ITER` is the same rule at runtime
