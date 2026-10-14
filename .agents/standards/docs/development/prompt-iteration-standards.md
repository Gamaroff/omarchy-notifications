---
title: Prompt and Skill Iteration Standards (the Rule of Three)
type: guide
status: active
created: 2026-10-14
updated: 2026-10-14
source: "rebirth-wallet/docs/development/prompt-iteration-standards.md (adapted 2026-10-14)"
---

# Prompt and Skill Iteration Standards: the Rule of Three

> **What this is.** A stopping rule. It says how many refinement passes a prompt, an agent skill,
> or a tool-use instruction gets before it goes to work, what distinct failure class each pass is
> responsible for, and what the fourth pass looks like when it arrives.

> **What this is not.** A quality bar to clear before writing anything, or a licence to ship a
> first draft. Three passes is a ceiling on *review in the abstract*, not a floor on care. It says
> nothing about how many times a prompt is revised **after** it has run and failed. That count is
> unbounded, and it is the only revision this document wants more of.

**The governing principle:**

> **Empirical failure on disk beats theoretical perfection in chat.**

A prompt that has failed once against a real input has told you more than a prompt that has passed
five self-reviews, because the self-review had no way to return "nothing". This is the same rule
[documentation conventions](documentation-conventions.md) apply to documents (*a rule with no
consumer and no gate is a preference*), pointed at prompts instead of docs.

---

## 1. The problem this exists to stop

### 1.1 A self-review cannot return "nothing"

Ask a language model to review its own instructions and it will find something. Asked again, it
will find something else. The findings are not fabricated exactly. Each one names a real if
improbable input. But the supply is inexhaustible, and its size is set by how many times you ask
rather than by how many defects exist. **A review that structurally cannot come back empty is not
evidence about the prompt.** It is evidence that you ran a review.

The tell is the shape of the finding. A defect points at an input that has been seen. A
manufactured finding points at one that could theoretically be constructed: *what if the filename
is only emoji, what if the user passes the flag twice, what if the file is empty and also locked.*

### 1.2 What the extra passes actually cost

| Cost | What it looks like | Why it bites |
| --- | --- | --- |
| **Instruction bloat** | The prompt triples in length across four passes | Every token is re-sent on every invocation, and the added rules compete with the user's actual task for attention |
| **Context overhead** | Guardrail prose crowds out the task's own detail | The instruction that matters is now the 40th of 60, and 60 rules do not get 60 equal readings |
| **Rule fragility** | Pass 4 adds a rule that quietly contradicts pass 2's | Nothing errors. The model picks one, differently on different runs, and the prompt becomes non-deterministic in a way no test names |
| **Brittleness** | Rules written against imagined inputs | Over-specification against a hypothetical shape is what breaks on the first real shape the author did not imagine |
| **False confidence** | Four passes feel like four times the assurance | None of them ran the prompt |

### 1.3 The runtime precedent

The runtime half of the same rule is already enforced: `MAX_ITER=5` caps the `/develop` and
`/qa-fix` loops in the [pipeline skills](../guides/pipeline-skills.md), because an agent asked to keep
improving will keep improving. This document supplies the missing case: the authoring loop, which
had no cap at all.

---

## 2. The Rule of Three

**Three passes before deployment. Each pass owns a different failure class, and passes are not
interchangeable.** A second sweep for the failure class pass 1 already covered is not pass 2.

A pass that finds nothing in its own class is **complete**, not failed. Do not re-run it looking
harder.

### Pass 1: Functional Baseline (the draft)

**Owns:** does this do the job at all, for the input it was written for.

- [ ] **Intent** stated in one sentence, at the top, in the imperative.
- [ ] **Inputs** named, with where each comes from (an argument, a file on disk, the conversation).
- [ ] **Output shape** stated: format, rough length, and destination (a file path, a tool call, a
      chat reply). "Write a summary" has no output shape; "write a 5-row markdown table to
      `docs/x.md`" does.
- [ ] **Success condition** stated, in terms someone else could check.
- [ ] **Explicit non-goals**: the one or two adjacent things it must not do.

**Exit when:** a reader with no prior context could produce output of the right shape.

### Pass 2: Cognitive Hardening

**Owns:** the model's systemic dispositions. These are properties of the *reader*, not of this
task, which is why they are worth a dedicated pass. They recur in every prompt and are invisible
from inside the task.

| Disposition | The mitigation to write in |
| --- | --- |
| **Confirmation bias** | Say what would *disprove* the expected answer, and require that be checked too |
| **Premise acceptance** | Grant permission to reject the request's framing: the premise may be wrong |
| **Sycophancy** | Grant permission to return **no findings**, and to disagree with the requester |
| **Adversarial posture** | Where a claim matters, require falsification over confirmation: run the tool, don't read the config ([§1.1](#11-a-self-review-cannot-return-nothing) is this rule turned on the prompt itself) |
| **Clean-room reading** | Assume no conversation history. Anything the agent "already knows" from chat is gone on the next invocation |
| **Evidence standard** | Name what counts as proof for this task: a command's exit status and output, a file that exists, a test that goes red when the behaviour is reverted |

**Exit when:** each of the six has been considered once and either written in or *deliberately*
declined. Declining five of six is a legitimate outcome for a small prompt.

### Pass 3: Operational Guardrails

**Owns:** the runtime, the environment, and the tools. These are the traps that have nothing to do
with the task's logic and everything to do with where it runs.

| Trap | The guardrail |
| --- | --- |
| **Chat state vs. disk state** | The agent's belief about a file is not the file. Require a re-read before an edit that depends on prior content |
| **Unbounded loops and fan-out** | State an iteration cap and what happens when it is hit. `MAX_ITER=5` is the precedent; escalate, do not loop |
| **Token / context budget** | Bound the output. Page or sample large inputs rather than dumping them |
| **Exit 0 is not success** | Name the failure signal per tool. A `sed` that matched nothing, an install that fell back to a public registry, and a passing run all exit 0 |
| **Idempotency** | State what a second run does. Re-running must not duplicate, and preferably resumes |
| **Destructive actions** | Name what requires confirmation, and what may never be done unprompted: force-push, delete, publish, credential writes |
| **Environment assumptions** | Name the versions, paths and credentials the prompt assumes, and what to do when one is absent |

**Exit when:** every tool the prompt names has a stated behaviour on failure, and every loop has a
cap.

### Pass 4+: the anti-pattern

**There is no pass 4 before deployment.** Past pass 3, refinement is generating work rather than
finding it. The signs, in the order they usually appear:

- **The hypothetical finding.** The input it protects against has never been seen and cannot be
  named concretely.
- **The restatement.** The new rule says what an existing rule says, in different words, in a
  different section. Two phrasings of one rule is worse than either alone: it reads as two rules.
- **The contradiction.** The new rule and an earlier one cannot both be followed. This is the
  expensive one, because nothing announces it.
- **The null diff.** The prompt changed; run it on the same input and the output is identical. The
  pass bought nothing and cost length.
- **Prose review.** The review is now improving the *writing* of the prompt rather than its
  behaviour.
- **Fear-driven scope.** Rules appear for failure modes that would be caught immediately and
  cheaply by simply running the thing.

**The rule past pass 3:**

> **After pass 3, the only admissible change is one traceable to an observed failure**: a run that
> went wrong, with the input that made it go wrong.

---

## 3. Decision rubric: when to ship

**Ship when every row in the left column is true.** One false row is a revision; do not use the
table to justify a fourth speculative pass on a row that is already true.

| Check | Ship if | Revise if |
| --- | --- | --- |
| **Passes done** | 1, 2 and 3 each run once | A pass has not been run in its own right |
| **Newest finding** | Names a concrete input you can write down | Begins "what if…" and cannot be made concrete |
| **Last pass's yield** | Changed observable behaviour | Reworded, reordered or restated |
| **Length trend** | Stable or shrinking | Growing with each pass |
| **Internal consistency** | No two rules conflict | Two rules conflict, or one hedges another |
| **Failure evidence** | Zero real runs so far | You have a failing run you have not addressed: fix that first, it beats any review |
| **Reversibility** | A bad output is cheap to discard | A bad output writes to a shared branch, a tracker, or anything outward-facing: gate it, then ship |

**The tiebreak, whenever the table is ambiguous:** ship it and run it. The cheapest remaining
source of information is a real invocation, and it is cheaper than the pass you are considering.

**Stop conditions. Any one of these means ship now:**

- The last pass produced no behavioural change.
- You are reviewing prose rather than behaviour.
- You cannot state the input that the next proposed rule would protect against.
- Running it costs less than the review you are about to do. (For most prompts, it does.)

---

## 4. Applying this

### 4.1 What it governs

Anything whose reader is a model: `AGENTS.md` and `CLAUDE.md`, agent skill files, system prompts,
tool-use instructions, and acceptance criteria written to be executed by an agent rather than read
by a person. Documents written for human readers are governed by
[documentation conventions](documentation-conventions.md) instead.

### 4.2 Where the passes happen

Agent skills are vendored into each repo's `.agents/skills/` and are never edited in place (see
[pipeline skills](../guides/pipeline-skills.md#vendored-skills-are-never-edited-in-place)). So the three
authoring passes on a skill happen in the skills' source repo. What happens in a consumer repo is
the empirical half: the run that failed, and the record of it. That repo is where skills meet real
inputs, so it is where the evidence is generated, even though the fix lands elsewhere.

### 4.3 Recording an observed failure

A failure that only exists in a chat transcript is not durable, and the next author will re-derive
it. Route it to something that persists, linked per
[documentation conventions](documentation-conventions.md#cross-references-are-two-way):

| The failure | Where it goes |
| --- | --- |
| A skill misbehaved on a real run | A bug report or task card naming the skill, the input, and the observed output; then the fix upstream in the skills' source repo |
| A repo-specific trap an agent keeps falling into | `AGENTS.md`, as a rule with the observation attached |
| A ruling that keeps getting re-derived | The repo's settled-rulings record, as its `AGENTS.md` names it |
| A one-off correction with no durable consumer | Nowhere. Not every observation earns a rule |

That last row is load-bearing. **Pass 4+ pressure does not disappear because this document forbids
it.** It gets redirected. The finding you cannot ship as a prompt rule is usually a finding you
should not have written down at all. Check whether it has a consumer before it becomes one more
line every future invocation pays for.

### 4.4 Reviewing someone else's prompt

Ask which pass the change belongs to. A review comment that fits none of the three classes, and
does not carry an observed failure, is a pass-4 finding regardless of who wrote it. Say so, and
let it ship.

---

## Related

- [Documentation conventions](documentation-conventions.md): the same "no consumer, no rule"
  principle, applied to documents
- [Pipeline skills](../guides/pipeline-skills.md): the pipelines' own bounded loops (`MAX_ITER`), which are
  this rule at runtime
