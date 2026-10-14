# Coding Standards

Taken from the existing code. Extend as decisions are made.

## Naming

- Plugin id and IPC target: `gamaroff.notifications`. Test IPC target: `gamaroff.notifications.test`.
- The state directory stays `omarchy-notification-center`, the pre-fork name, so existing archives are kept.
- Store subcommands are single lowercase verbs (`list`, `remove`, `seen`), mostly implemented as `cmd_<verb>`.
- A setting's key is camelCase in `manifest.json` (`mutedNotifications`); its label is a plain sentence.

## Formatting

- Two-space indent in QML, JS and bash. No semicolons in QML or JS.
- JS libraries use `var` and `function` only: no `let`, `const`, arrow functions, `require` or `import`.
- Glyphs in QML are `\u` escapes, not literal characters, so editors and patches cannot mangle them.
- Comments are prose that say why, above the code they explain.

## Linting

- None configured. `bin/notification-center` passes `shellcheck` clean; keep it that way.
- New logic goes in a `.pragma library` file with a `node:test` suite, so it can be tested outside QML.

## Patterns to avoid

- Never store or run a notification's action command. Keep only an absolute image path, opened by
  argument (`xdg-open`), never through a shell.
- Never pass a sender-chosen app name to the focus helper unchecked; it must match
  `^[A-Za-z0-9][A-Za-z0-9 ._-]{0,63}$`.
- Never print non-JSON from the store: errors go through `die`, which prints `{"ok":false,"error":...}`.
- Never write to Omarchy's notification directory. Write the archive only under `flock`, and keep `umask 077`.
- Only images enter the archive: over 5 MB is never copied, and when `file` is installed anything it does
  not call `image/*` is dropped.
- No blocking calls in QML: every store call is a `Process`, and JSON from it is parsed in `try`/`catch`.
- Mute rules filter what is shown, never what is archived, so removing a rule brings notifications back.
- No grouping of identical notifications.
- A setting changes in both `manifest.json` and the README settings table.
