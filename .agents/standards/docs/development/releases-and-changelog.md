---
title: "Releases and changelog"
type: guide
status: active
created: 2026-10-14
updated: 2026-10-14
source: "new; versioning from rebirth-wallet/docs/development/git-strategy.md §6 (adapted 2026-10-14)"
---

# Releases and changelog

## 1. Versions

- SemVer: `MAJOR.MINOR.PATCH`. Breaking change → MAJOR; new backwards-compatible feature → MINOR; fix →
  PATCH. Before 1.0.0, a breaking change may bump MINOR.
- The version lives in one file, named in the repo's `AGENTS.md`.
- Tags are `vX.Y.Z`, annotated, on `main` only. `main` moves only by a release or hotfix merge, and each
  merge is tagged; an untagged merge on `main` is an error.

## 2. Changelog

Every repo has `CHANGELOG.md` at the root, in [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
form. Start from [templates/CHANGELOG.md](../../templates/CHANGELOG.md).

- An `## [Unreleased]` section sits at the top. Each merged work item adds its user-visible change there,
  in the same PR, under `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed` or `Security`.
- Write for the user of the repo, not the developer: what changed for them, not which files moved.
  Internal-only work (tests, refactors, docs process) needs no entry.
- At release, `[Unreleased]` becomes `## [X.Y.Z] - YYYY-MM-DD`, and a fresh empty `[Unreleased]` goes above it.
- Never rewrite a released section. A correction goes in the next release.

## 3. Release steps (direct)

There are no `release/*` branches. A release is one small PR into `develop`, then `develop` into `main`.

1. Check `develop` is green: run the repo's quality gate (named in its `AGENTS.md` / `skills-config.yaml`).
2. On `chore/release-X.Y.Z` from `develop`: bump the version file, close `[Unreleased]` as `[X.Y.Z]` with
   today's date, commit `chore(release): X.Y.Z`, PR into `develop`, merge.
3. PR `develop` into `main` titled `Release X.Y.Z`; merge with a merge commit (`--no-ff`).
4. Tag `main`: `git tag -a vX.Y.Z -m "Release X.Y.Z"`. Push `main` and the tag (needs the user's approval).
5. Optional: `gh release create vX.Y.Z --notes-from-tag` or with the changelog section as notes.
6. Run the repo's post-release step, if its `AGENTS.md` names one (for example an install update).

## 4. Hotfix steps

1. `hotfix/X.Y.Z` from `main`, with the fix, the patch bump and a `[X.Y.Z]` changelog section.
2. PR into `main`, merge, tag `vX.Y.Z`, push with approval.
3. PR the hotfix branch into `develop` so the fix and the changelog entry are not lost. Delete the branch
   after both merges.
4. Run the post-release step.

## 5. What a pipeline does and does not do

`/develop-next` and the `/develop-*` pipelines merge into `develop` only. They never release. A release is
always started by the user.
