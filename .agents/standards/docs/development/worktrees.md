---
title: "Worktrees"
type: guide
status: active
created: 2026-10-14
updated: 2026-10-14
source: "tinker-city/docs/development/parallel-development-runbook.md (adapted 2026-10-14)"
---

# Worktrees

## 1. Where they live

Inside the repo, never beside it:

```
<repo>/.worktrees/<name>
```

`<name>` is the branch's last segment, with dots kept: `story.1.2.leak-actions`, `bug.3.badge-count`.
`/develop-batch` names its own worktrees `batch-<slug>` (§5). Nothing is created in the parent directory
(for example `~/Development`).

## 2. Repo setup (once)

- `.gitignore` has `.worktrees/`.
- Linters and test discovery skip it, or they lint and test every worktree twice. Set each tool's
  exclude or ignore setting, or scope discovery to the source and test directories.
- File watchers and indexers (editors, graph tools) exclude it.

## 3. Create, use, remove

```bash
git fetch origin
git worktree add .worktrees/story.1.2.leak-actions -b feature/story.1.2.leak-actions origin/develop
cd .worktrees/story.1.2.leak-actions
# copy gitignored files the work needs (for example .claude/settings.json, .env), keeping their paths
```

- A worktree carries no ignored files. Seed the ones the work needs, path for path. In agent-skills,
  `developBatch.worktreeSeedPaths` lists them.
- Agent links (`CLAUDE.md`, `.claude/skills`) are gitignored too: recreate them in the worktree (see
  [agent-files.md](agents/agent-files.md)).
- One branch can be checked out in only one worktree. Do not check out `develop` or `main` in a worktree
  while the main checkout uses it.
- When the branch is merged: `git worktree remove .worktrees/<name>`, then delete the branch. Never
  `rm -rf` a worktree directory; if one was deleted by hand, run `git worktree prune`.
- A worktree whose pipeline halted is left in place until the halt is resolved.

## 4. Parallel work

- Develop in parallel, merge serially. Each merger rebases or merges the new `develop` tip before its PR merges.
- Roadmap rows carry `touches:` tags for `/develop-batch`: `!` = exclusive (serialise), `~` or unmarked =
  additive (parallel is fine, the second merger reconciles), `+own` = self-contained.
- Merges, roadmap ticks and registry updates happen one at a time, from the main checkout.

## 5. agent-skills batch worktrees

From agent-skills v0.57.0, `/develop-batch` and `/create-parallel-stories` create worktrees under
`developBatch.worktreeRoot` in `skills-config.yaml`, default `.worktrees`. `/develop-batch` names each one
`<worktreeRoot>/batch-<slug>`, and adds the root to `.git/info/exclude` if `.gitignore` lacks it. Leave the
key at its default.

Skills vendored before v0.57.0 create sibling paths (`../tc-wt-<slug>`, `../wt-*`, `../worktrees/`), which
break §1. Update the skills (`setup-consumer.sh --update`); until then, change the path in the generated
command to `.worktrees/<name>` before running it.
