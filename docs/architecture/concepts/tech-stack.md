# Tech Stack

Taken from the code and `manifest.json`. Versions are not pinned: the plugin runs on whatever Omarchy ships.

## Runtime

- Omarchy shell (`omarchy-shell`, built on Quickshell). It loads the plugin from `manifest.json`: kinds
  `service` and `bar-widget`, entry points `Service.qml` and `Panel.qml`. Contract:
  `/usr/share/omarchy/shell/README.md`, "Plugin manifest".
- Input: Omarchy's notification service, which writes one JSON file per notification under
  `~/.local/state/omarchy/notifications/` (and `history/`). Do Not Disturb goes through the
  `omarchy-shell notifications setDnd` IPC target.
- Required programs: `jq` and `inotifywait` (both ship with Omarchy; the store fails with a JSON error
  without them). Optional: `file` (the image check; skipped without it), `magick` (scales previews to 720 px).
- Also called: `flock`, `xdg-open` (opens a picture), `$OMARCHY_PATH/bin/omarchy-hyprland-focus-app`
  (focuses the sending app).

## Languages

- QML (Qt Quick, Quickshell, `Quickshell.Io`, Omarchy's `qs.Commons` and `qs.Ui`) for the service, panel
  and cards.
- JavaScript as QML `.pragma library` files: `lib/`, `components/WebApps.js`, `Store.js`. ES5-style plain
  script, so the same files run under Node in tests.
- Bash for the store, `bin/notification-center`. Every subcommand prints one JSON object or array.

## Frameworks

- No build step, no package manager, no dependencies to install.
- Tests: Node's built-in `node:test` and `node:assert`, loading the `.pragma library` files through
  `node:vm`. Run with `node --test`. QML and the bash store have no automated tests.
- Lint: none configured.

## Infrastructure

- Distribution: public git repo `Gamaroff/omarchy-notifications`, installed with `omarchy plugin add`.
  Omarchy's checkout follows `main`. No CI.
- Storage: `~/.local/state/omarchy-notification-center/` (`archive.jsonl`, `images/`, `seen`), `0700`.
  Nothing leaves the machine; there is no network use.
