---
title: "Agent files"
type: guide
status: active
created: 2026-10-14
updated: 2026-10-14
source: "new; pattern from rebirth-wallet (untracked CLAUDE.md) and agent-skills scripts/link-skills.sh (2026-10-14)"
---

# Agent files

## 1. What a repo commits

| Path | Committed | Role |
| --- | --- | --- |
| `AGENTS.md` | yes | The only agent instruction file. Imports the universal guide on its first lines. |
| `.agents/skills/` | yes | The only skills directory, vendored from `Gamaroff/agent-skills`. |
| `.agents/standards/` | yes | The universal guide, vendored from `Gamaroff/agent-standards` (§3). |
| `CLAUDE.md`, `GEMINI.md`, … | **no** | Local symlinks to `AGENTS.md`, gitignored. |
| `.claude/skills`, other agents' skill dirs | **no** | Local symlinks to `../.agents/skills`, gitignored. |
| `.claude/settings.json` | repo's choice | Project hooks (for example the pipeline hooks). Not an instruction file. |

Why links are never committed: some plugin installers and validators refuse symlinks in a tree, CI
checkouts must not depend on them, and each user runs different agents.

## 2. Creating the links

Each user creates the links for the agents they use, once per clone or worktree. For Claude Code:

```bash
ln -s AGENTS.md CLAUDE.md
mkdir -p .claude && ln -s ../.agents/skills .claude/skills
```

Other agents follow the same shape: their instruction file links to `AGENTS.md`, their skills directory
links to `../.agents/skills`. agent-skills documents the agents it supports and their paths.

`.gitignore` in every repo:

```gitignore
# Agent links: each user creates their own (universal guide, docs/development/agents/agent-files.md)
CLAUDE.md
GEMINI.md
.claude/skills
```

Add a line for any other agent link a user creates.

### A repo that committed its links

Untrack them in one commit with the `.gitignore` lines: `git rm --cached CLAUDE.md .claude/skills`. The
local links stay.

Until every branch has that commit, git deletes the local links whenever it moves the checkout between a
branch that tracks them and one that does not: a switch, a checkout or a fast-forward pull. Recreate them
with the commands above. It stops once `main` has the commit, at the next release.

## 3. Installing the guide and the import line

The guide is vendored, not cloned: a release of `Gamaroff/agent-standards` is copied into
`.agents/standards/` and committed, so it works in CI, cloud agents and any checkout. Its `VERSION` file
names the release. From the repo root:

```bash
# first install (while the source repo is private, fetch the script with gh instead of curl:
# gh api -H "Accept: application/vnd.github.raw" repos/Gamaroff/agent-standards/contents/scripts/install.sh | bash)
curl -fsSL https://raw.githubusercontent.com/Gamaroff/agent-standards/main/scripts/install.sh | bash

# update to the latest release, or pin one with --ref vX.Y.Z; --dry-run shows the changes
bash .agents/standards/scripts/install.sh
```

The script replaces `.agents/standards/` and, only where missing, creates `AGENTS.md` and `CHANGELOG.md`
from the templates, adds the import block to `AGENTS.md`, and adds the `.gitignore` lines from §2. Commit
the result as `chore(standards): install vX.Y.Z` or `chore(standards): update to vX.Y.Z`.

Each repo's `AGENTS.md` starts with:

```markdown
@.agents/standards/AGENTS.md

> Universal rules: `.agents/standards/AGENTS.md`, vendored from `Gamaroff/agent-standards`.
> Read it before working if your agent does not follow `@` imports.
```

Claude Code loads the `@` import through the `CLAUDE.md` link. Other agents read the quoted sentence and
open the file.

## 4. Editing

- Never edit `.agents/skills/` in place. Fix the skill in `Gamaroff/agent-skills`, then run its
  `setup-consumer.sh --update` and commit the result as `chore(skills): …`.
- Never edit `.agents/standards/` in place. Change the rule in `Gamaroff/agent-standards`, release it,
  then re-run `.agents/standards/scripts/install.sh`. The script refuses to replace a copy with local edits.
- Editing `AGENTS.md` or the universal guide is a prompt edit: follow
  [prompt-iteration-standards.md](../prompt-iteration-standards.md).
- Keep `AGENTS.md` a map: facts that apply to every task, links for the rest. Move a section into a linked
  doc once the file passes about 200 lines.
