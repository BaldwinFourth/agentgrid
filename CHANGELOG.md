# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/) and the project uses [Semantic Versioning 2.0.0](https://semver.org/).

## [Unreleased]

## [0.2.0] - 2026-11-07
### Added
- README: a "Privacy first" section (no telemetry, no network connections, nothing saved or sent) and a link to claude-code-broadcast.

### Changed
- Launch at Login is now opt-in: AgentGrid no longer adds itself as a login item on launch. Turn it on from the right-click menu. Existing login items are left as they are.

### Fixed
- Turning Launch at Login off from the menu no longer gets undone the next time AgentGrid is opened.

## [0.1.1] - 2026-11-03
### Fixed
- Clicking the menu bar icon to bring the agent windows back only beeped and left Terminal hidden when Terminal listed a helper window that has no id or tabs (seen after connecting an audio device such as a HomePod or a microphone). Such windows are now skipped, so the agent windows are tiled again.

## [0.1.0] - 2026-11-01
### Added
- Menu bar button that tiles every Terminal window running an AI agent CLI into an even grid and brings them to the front (1–3 side by side; 4 → 2×2, 5–6 → 2×3, 7–9 → 3×3; a short last row stretches). A second click hides Terminal and reactivates the previous app.
- Agent detection for `claude`, `codex`, `gemini`, `grok`, `agy`, `opencode`, `aider`, `cursor-agent` and `qwen`, including CLIs launched through `node`, `bun`, `deno` or `python`.
- Right-click menu: version, Launch at Login, Quit. Registers as a login item on first launch.
- `AgentGrid --show` to tile once from the shell.
- `./build.sh test|install`: pure-logic tests; build, ad-hoc sign and install to `~/Applications`.

[unreleased]: https://github.com/BaldwinFourth/agentgrid/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/BaldwinFourth/agentgrid/compare/v0.1.1...v0.2.0
[0.1.1]: https://github.com/BaldwinFourth/agentgrid/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/BaldwinFourth/agentgrid/releases/tag/v0.1.0
