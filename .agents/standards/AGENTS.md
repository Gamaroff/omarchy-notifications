# Universal agent guide

Rules for every repo whose `AGENTS.md` imports this file. They cover process: git, releases, worktrees,
agent files, docs and pipelines. The repo's own `AGENTS.md` covers its facts: stack, commands, layout,
install, gotchas. When the two conflict, the repo's `AGENTS.md` wins on its facts and this file wins on
process. A repo that needs an exception to a rule here states it in its `AGENTS.md`, with the reason.

Source: `Gamaroff/agent-standards`, vendored into each repo at `.agents/standards/`. Detail docs are
linked, not imported: read one when the task touches its topic. Every `docs/` and `templates/` link below
is relative to this file, so in a repo it means `.agents/standards/docs/…`. A repo may have its own file
at `docs/…`; that file is the repo's, not this guide's.

## Working style

Think before coding, keep it simple, change only what the request needs, and define how you will know it
worked before you start.
Detail: [docs/development/agents/working-style.md](docs/development/agents/working-style.md).

## Agent files

- `AGENTS.md` is the only agent instruction file a repo commits. `.agents/skills/` is the only skills
  directory it commits. `.agents/standards/` holds this guide.
- Every other agent's file is a **local, gitignored symlink**: `CLAUDE.md -> AGENTS.md`,
  `.claude/skills -> ../.agents/skills`, and the same for any other agent. Never commit one.
- `.agents/skills/` is vendored from `Gamaroff/agent-skills` and `.agents/standards/` from
  `Gamaroff/agent-standards`. Never edit either in place; fix upstream and re-vendor.
- Editing `AGENTS.md`, this guide or a skill is a prompt edit: follow the Rule of Three.
- Detail: [docs/development/agents/agent-files.md](docs/development/agents/agent-files.md),
  [docs/development/prompt-iteration-standards.md](docs/development/prompt-iteration-standards.md).

## Git

- Branches: `main` holds released states only; `develop` is integration. Work branches off `develop`
  (`feature/*`, `bugfix/*`, `docs/*`, `chore/*`) and reaches it through a PR. `hotfix/*` branches off `main`.
- No direct commits to `main` or `develop`, docs included. One exception: `/develop-next` commits its
  roadmap tick on `develop` after it merges.
- Commit with the `/commit-changes` skill: Conventional Commits, `type(scope): summary`, scope = the work
  item (`story.1.2`, `task.7`, `bug.3`) where there is one.
- Merge finished branches with a merge commit (`--no-ff`) and delete them. Never force-push `main` or `develop`.
- Ask before pushing, except where a pipeline the user started (for example `/develop-next`) pushes its own
  branch and merges into `develop`. Pushing `main` or a tag always needs the user's approval.
- Detail: [docs/development/git-strategy.md](docs/development/git-strategy.md).

## Releases and changelog

- Every repo has `CHANGELOG.md` (Keep a Changelog) and SemVer versions.
- Release directly: bump the version and close the `[Unreleased]` section on a `chore/release-X.Y.Z`
  branch into `develop`, then PR `develop` into `main`, merge with a merge commit, tag `vX.Y.Z` on `main`.
- `main` moves only by a release or hotfix merge, and each one is tagged. Hotfixes branch off `main` and
  merge into `main` and `develop`.
- The repo's `AGENTS.md` names its version file and any post-release step.
- Detail: [docs/development/releases-and-changelog.md](docs/development/releases-and-changelog.md).

## Worktrees

- Worktrees live inside the repo, at `<repo>/.worktrees/<name>`, never beside it.
- `.worktrees/` is gitignored and excluded from linters and test discovery.
- Remove them with `git worktree remove`, never `rm -rf`.
- Detail: [docs/development/worktrees.md](docs/development/worktrees.md).

## Docs

- Work items live in self-named directories; file names use dots between parts and hyphens within words.
- Story and task status values are the pipelines' enums only. Change Logs are append-only.
- Links point at tracked files and are added both ways in the same change.
- Detail: [docs/development/documentation-conventions.md](docs/development/documentation-conventions.md),
  [docs/architecture/adr-conventions.md](docs/architecture/adr-conventions.md).

## Pipelines

`/develop-next` and the `/develop-*` and `/qa-*` skills run work items from the current repo's
`docs/development/project-completion-roadmap.md`. The repo's `skills-config.yaml` sets the gates.
Detail: [docs/guides/pipeline-skills.md](docs/guides/pipeline-skills.md).

## What each repo's AGENTS.md must contain

Start from [templates/AGENTS.repo.md](templates/AGENTS.repo.md): the import line, what the repo is,
commands (test, lint, gate), layout, install or deploy, release specifics (version file, post-release step),
gotchas, and any exception to this guide.
