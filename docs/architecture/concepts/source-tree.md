# Source Tree

```
.
├── manifest.json              # id gamaroff.notifications, version, entry points, settings schema + defaults
├── Service.qml                # one per shell: runs `watch`, polls `list` every 10 s, owns entries and lastSeen
├── Panel.qml                  # bar widget (one per monitor): the bell, the panel, search, clicks; IPC target
├── Store.js                   # one-per-engine handle on the service, for bars whose serviceFor() returns null
├── components/
│   ├── NotificationRow.qml    # one card
│   └── WebApps.js             # which installed web app a browser notification came from
├── lib/
│   ├── Mute.js                # "Hide notifications containing" rules: parse, isMuted, filter
│   └── SlackLink.js           # the Slack conversation a notification was about, from Slack's log
├── bin/
│   └── notification-center    # bash store: sync, watch, list, remove, clear, seen, unread, prune, seed, backfill
├── tests/                     # node:test suites for lib/ and components/WebApps.js
├── README.md                  # user docs and the settings table
├── preview.png                # README screenshot
├── CHANGELOG.md
├── AGENTS.md                  # repo agent instructions (CLAUDE.md links here, gitignored)
├── docs/
│   ├── architecture/concepts/ # these always-loaded context files
│   ├── development/epic-registry.md
│   └── tasks/task-registry.md
├── scripts/generate-prd-epic-index.mjs   # vendored by agent-skills; do not edit
├── .agents/                   # vendored skills and standards (.claude/skills links here, gitignored)
├── .claude/settings.json      # PreCompact and Stop hooks for the develop pipelines
├── skills-config.yaml
└── tracker-workflow.yaml
```

Data flow: Omarchy writes a notification file; `notification-center watch` copies it into the archive
and prints it as a JSON line; `Service.qml` adds it to `entries`, filtered by the mute rules; each
`Panel.qml` reads the service and renders the cards.

Outside the repo, the plugin writes only to `~/.local/state/omarchy-notification-center/`.
