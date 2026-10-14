@.agents/standards/AGENTS.md

> Universal rules: `.agents/standards/AGENTS.md`, vendored from `Gamaroff/agent-standards`.
> Read it before working if your agent does not follow `@` imports.

# AGENTS.md

Omarchy Notifications (`gamaroff.notifications`) is an Omarchy shell plugin: a bar widget and service
that archive every desktop notification and show them in a panel. It is a fork of
`jankeesvw/omarchy-notification-center` and runs inside the Omarchy shell (Quickshell/QML) on the user's
own Linux desktop.

## Commands

- Tests: `node --test`, from the repo root (well under a second; 17 tests, no dependencies to install).
- Lint: none configured.
- Quality gate (also `skills-config.yaml` `develop.fastGateCommand` and `developNext.qualityGateCommand`):
  `node --test`.
- Plugin check: `omarchy plugin validate <plugin-folder>` checks a folder against Omarchy's manifest schema.

## Layout

- `manifest.json`: plugin id, version, entry points and the settings schema with defaults.
- `Service.qml`: the service entry point; runs the store and holds the archive.
- `Panel.qml`: the bar widget entry point; the bell and the panel.
- `components/`: `NotificationRow.qml` (one card) and `WebApps.js` (which web app a browser notification
  came from).
- `lib/`: `Mute.js` (the "Hide notifications containing" rules) and `SlackLink.js` (the Slack
  conversation a notification was about).
- `Store.js`: a one-per-engine handle on the service, for bars whose widgets cannot get it from the shell.
- `bin/notification-center`: the storage side, in bash. Subcommands `list`, `remove`, `seed`, `backfill`,
  `watch`, `sync`, `seen`, `unread`, `prune`.
- `tests/`: `node:test` unit tests for `lib/` and `components/WebApps.js`.
- `README.md`: user docs, including the settings table. `preview.png`: the README screenshot.
- `docs/`: architecture concept files (`docs/architecture/concepts/`, still unfilled templates), epic and
  task registries.
- Agent tooling: `skills-config.yaml` (pipeline config; tracker is GitHub), `tracker-workflow.yaml`
  (board columns, generated from a template), `scripts/generate-prd-epic-index.mjs` (vendored by
  agent-skills and overwritten on update; do not edit it here), `.claude/settings.json` (PreCompact and
  Stop hooks that run `.agents/skills/develop-story/scripts/`).

## Install or deploy

Users install with `omarchy plugin add https://github.com/Gamaroff/omarchy-notifications.git --enable`,
which clones the repo into `~/.config/omarchy/plugins/gamaroff.notifications`, and update with
`omarchy plugin update`. Remove with `omarchy plugin remove gamaroff.notifications`. Needs `jq` and
`inotifywait`, which Omarchy ships.

On the owner's machine it is installed the same way, with
`omarchy plugin add git@github.com:Gamaroff/omarchy-notifications.git`. Omarchy keeps its own git checkout
at `~/.config/omarchy/plugins/gamaroff.notifications`, and `omarchy plugin update` fast-forwards it to the
remote default branch, `main`. Only released code runs. The dev clone `~/Development/omarchy-notifications`
is never the running copy: develop and switch branches there freely.

- The widget sits in the bar's center section, at index 5, with its own `mutedNotifications` setting in
  `~/.config/omarchy/shell.json` (managed by chezmoi). `omarchy plugin enable` keeps the position but drops
  the setting; `chezmoi apply ~/.config/omarchy/shell.json` puts it back.
- The `omarchy plugin` commands fail with "omarchy-shell is not responding" under the default 2s IPC
  timeout. Run them with `OMARCHY_SHELL_IPC_TIMEOUT=20s`.

## Releases

- Version file: `manifest.json` (`version`).
- Pushing `main` is what ships.
- Post-release step: `omarchy plugin update gamaroff.notifications --yes`, then `omarchy-restart-shell` (the
  shell caches QML).

## Gotchas

Privacy and safety:

- The archive is every notification the user was sent, two-factor codes included. It lives in
  `~/.local/state/omarchy-notification-center/` (`0700`, archive `0600`) and must never enter the repo;
  `.gitignore` blocks `*.jsonl` for that reason.
- Never store or run a notification's action command: the sender chose it. Only an absolute path to an
  image is kept, and it is opened by argument, never through a shell.
- Only files that are actually images are copied into the archive.

The store (`bin/notification-center`):

- Every subcommand prints JSON, one object or one array, failures included, so nothing reaches the panel
  as a parse error.
- It sets `umask 077` once at the top; everything it writes stays private.
- It only reads Omarchy's own notification directory (`~/.local/state/omarchy/notifications/`) and never
  writes there.
- `NC_SRC_DIR`, `NC_SRC_HISTORY` and `NC_STORE` point it at scratch directories. That is the only way to
  exercise the watcher without waiting for real notifications.
- The state directory keeps the old name `omarchy-notification-center`, not the plugin id
  `gamaroff.notifications`. Renaming it would orphan existing archives.

QML and JavaScript:

- `lib/*.js`, `components/WebApps.js` and `Store.js` start with `.pragma library`. The tests strip that
  line and run the rest in a `node:vm` context, so these files must stay plain script: no `require`, no
  `import`.
- No grouping, on purpose: ten identical notifications are ten cards.
- The panel is pinned to the right edge of the screen, so the bell belongs at the far right of the bar.

Settings and validation:

- A setting is defined in `manifest.json` (defaults and schema) and described in the README settings
  table. Change both together.
- `omarchy plugin validate .` fails in the dev clone: Omarchy forbids symlinks inside a plugin folder, and
  the local agent links (`CLAUDE.md`, `.claude/skills`) are symlinks. A fresh clone, including Omarchy's
  installed checkout, does not have them; validate one of those instead.
