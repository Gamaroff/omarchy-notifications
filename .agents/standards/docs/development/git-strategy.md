---
title: "Git strategy"
type: guide
status: active
created: 2026-10-14
updated: 2026-10-14
source: "rebirth-wallet/docs/development/git-strategy.md §1-3, §5.1, §5.3, §6, §9 (adapted 2026-10-14)"
---

# Git strategy

Gitflow, simplified for repos with one maintainer and direct releases.

## 1. The one rule

Work flows one way:

```
feature/bugfix/docs/chore  →  develop  →  main
```

Two branches merge back down so nothing is lost: a release reaches `develop` before `main`, and a hotfix
merges into both `main` and `develop`.

**Everything reaches `develop` through a branch and a PR. There is no doc-only exception.** "Small enough
to skip review" is a judgement made by the person least able to make it, before anyone else has looked.
The one direct commit on `develop` is `/develop-next`'s roadmap tick, made after it merges the item's PR.

## 2. Branches

| Branch | Lives | From | Into | Purpose |
| --- | --- | --- | --- | --- |
| `main` | permanent | — | — | Released states only. Moves only by a release or hotfix merge, each tagged `vX.Y.Z`. |
| `develop` | permanent | `main` (once) | `main` (a release) | Integration. The base for all new work. |
| `feature/*` | until merged | `develop` | `develop` | A story, task or epic document. |
| `bugfix/*` | until merged | `develop` | `develop` | A bug found before release. |
| `docs/*`, `chore/*` | until merged | `develop` | `develop` | Docs-only or housekeeping work, including `chore/release-X.Y.Z`. |
| `hotfix/*` | until merged | `main` | `main` and `develop` | A defect in a released state that cannot wait. |

There are no `release/*` branches: releases are direct (see [releases-and-changelog.md](releases-and-changelog.md)).
Epic integration branches are not used unless a repo's `AGENTS.md` opts in.

## 3. Naming

Dots separate structural parts, hyphens separate words, all lowercase.

| Type | Pattern | Example |
| --- | --- | --- |
| Story | `feature/story.{e}.{s}.{name}` | `feature/story.1.2.leak-actions` |
| Task | `feature/task.{n}.{name}` | `feature/task.7.lint-config` |
| Epic document | `feature/epic.{n}.{name}` | `feature/epic.2.leak-panel` |
| Bug | `bugfix/bug.{n}.{name}` | `bugfix/bug.3.badge-count` |
| Docs | `docs/{name}` | `docs/readme-install` |
| Chore | `chore/{name}` | `chore/release-0.2.0`, `chore/skills-update` |
| Hotfix | `hotfix/{version}` or `hotfix/{name}` | `hotfix/0.2.1` |

The agent-skills `/create-branch` skill produces these names.

## 4. Lifecycles

### Feature, bugfix, docs, chore

```bash
git switch develop && git pull --ff-only origin develop
git switch -c feature/story.1.2.leak-actions
# work, committing with /commit-changes
git rebase origin/develop          # only while the branch is unpublished
git push -u origin feature/story.1.2.leak-actions
# open a PR into develop (/create-pr), merge with a merge commit, delete the branch
```

### Hotfix

```bash
git switch main && git pull --ff-only origin main
git switch -c hotfix/0.2.1
# fix, bump the patch version, add the CHANGELOG entry
# PR into main, merge with a merge commit, tag v0.2.1 on main (needs approval to push)
# then PR the hotfix branch into develop so develop has the fix; delete the branch after both merges
```

## 5. Commits

- Use the `/commit-changes` skill. It writes Conventional Commits: `type(scope): summary`, with a bulleted
  body for anything non-trivial.
- Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `perf`, `build`, `ci`, `revert`.
- Scope is the work item where there is one: `feat(story.1.2): …`, `fix(bug.3): …`, `docs(epic.2): …`,
  `chore(task.7): …`. Releases use `chore(release): X.Y.Z`; skill updates use `chore(skills): …`;
  guide updates use `chore(standards): …`.
- Commit finished work freely. One logical change per commit; split unrelated changes.
- No attribution trailers unless the repo's `AGENTS.md` asks for them.

## 6. Merge, rebase and push policy

- Integrate a finished branch with a merge commit (`--no-ff`, `gh pr merge --merge --delete-branch`).
- Rebase an in-flight branch on `origin/develop` only while it is unpublished. Once pushed, update it by
  merging `develop` into it.
- Never force-push `main` or `develop`. Force-push only your own unshared branches.
- Ask before pushing. Exception: a pipeline the user started pushes its own work branch and opens the PR
  (`/develop-story`, `/develop-task`, `/develop-bug`). `/develop-next` also merges that PR into `develop`
  and pushes its roadmap tick. Pushing `main` or a tag always needs approval.
- Delete merged branches, local and remote.

## 7. Quick reference

```
New work ........ branch FROM develop → PR INTO develop
Release ......... chore/release-X.Y.Z → develop; PR develop → main; tag vX.Y.Z on main
Hotfix .......... branch FROM main → PR INTO main (tag) → merge INTO develop
Never ........... commit straight to main or develop; force-push them; merge main into a feature branch
Always .......... /commit-changes; merge commits; tag every merge into main; delete merged branches
```
