# Changelog

All notable changes to this project are recorded here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.1] - 2026-10-14

### Added

- `agent-files.md` and the README: how to untrack links a repo committed, and why git deletes the
  local links when switching branches until `main` has that commit.

## [0.2.0] - 2026-10-14

### Added

- `LICENSE`: MIT. The installer copies it into `.agents/standards/` with the guide.

### Changed

- `scripts/install.sh` reuses the source recorded in `.agents/standards/VERSION`, so updating from a
  mirror or local clone needs no `--source`. `--source` and `AGENT_STANDARDS_SOURCE` still override it.

## [0.1.3] - 2026-10-14

### Changed

- `README.md`: a full guide to installing, updating, pinning and removing the standards in a repo,
  using another git host, and troubleshooting.

## [0.1.2] - 2026-10-14

### Changed

- `docs/development/worktrees.md`: agent-skills v0.57.0 keeps batch worktrees inside the repo under
  `developBatch.worktreeRoot`; the manual path fix is now only for skills vendored before it.

## [0.1.1] - 2026-10-14

### Fixed

- `scripts/install.sh` no longer prints `warning: … is not a commit!` when installing a release tag.

## [0.1.0] - 2026-10-14

### Added

- The universal agent guide, `AGENTS.md`, for every repo to import.
- Detail docs: git strategy, releases and changelog, worktrees, documentation conventions, prompt
  iteration standards, working style, agent files, ADR conventions, and the pipeline skills.
- Templates for a repo's `AGENTS.md` and `CHANGELOG.md`.
- `scripts/install.sh`, which vendors a release into a repo's `.agents/standards/` and updates it.
