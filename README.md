# AgentGrid

**A tiny macOS menu bar app: one click shows every AI coding agent you have running in Terminal — tiled in a clean grid. Click again and they're gone.**

**macOS 14+ · Native Swift · Menu bar app · No telemetry · Zero dependencies · MIT license**

Running three Claude Code sessions, a Codex run and a Gemini CLI chat in separate Terminal windows? AgentGrid finds every Terminal window that has an AI agent in it, brings them all to the front and splits the screen evenly between them. A second click hides Terminal and drops you straight back into whatever you were doing — your editor, your browser, your game.

- **Zero setup.** Sessions are detected automatically; nothing to configure, no window to tag.
- **Even grid, any count.** 1 window fills the screen, 2–3 sit side by side, 4 → 2×2, 5–6 → 2×3, 7–9 → 3×3, and so on (⌈√n⌉ columns). A short last row stretches to fill — no holes.
- **Stable positions.** Windows are ordered by when they were opened, so each session lands in the same spot every time.
- **Only agents.** Plain shell windows are never moved or resized. (The second click hides Terminal as a whole, so they hide too: macOS hides apps, not single windows.)
- **Back where you were.** The second click hides Terminal and reactivates the app you came from. Sessions keep running.
- **Tiny and native.** ~250 lines of Swift, no dependencies, no Accessibility permission — only Automation access to Terminal.

## Privacy first

- **Runs entirely on your Mac.** No telemetry, no analytics, no crash reporting, no update checks, and it makes no network connections. There is no third-party code either: the app has zero dependencies.
- **Reads, never saves.** To find agent sessions it reads the process list (`ps`, including command lines) and Terminal's window and tab list (AppleScript) in memory. Nothing is saved or sent anywhere; error notices go only to the macOS system log on your Mac.
- **Minimal permissions.** Only Automation access to Terminal. No Accessibility, Screen Recording or Full Disk Access.
- **Opt-in only.** It changes no system setting on its own. Launch at Login stays off until you turn it on from the right-click menu.

## Supported agents

Detected by process name, including CLIs launched through `node`, `bun`, `deno` or `python`:

`claude` (Claude Code) · `codex` (OpenAI Codex CLI) · `gemini` (Gemini CLI) · `grok` · `agy` (Antigravity) · `opencode` · `aider` · `cursor-agent` · `qwen`

Missing one? Add its executable name to `agentProcessNames` in [`Sources/AgentGrid/Layout.swift`](Sources/AgentGrid/Layout.swift) — PRs welcome.

## Install

Requirements: macOS 14 or later, Terminal.app, Xcode Command Line Tools (`xcode-select --install`).

```bash
git clone https://github.com/BaldwinFourth/agentgrid.git
cd agentgrid
./build.sh install   # runs the tests, builds, ad-hoc signs, installs to ~/Applications/AgentGrid.app and launches it
```

The first time you click the grid icon, macOS asks **"AgentGrid wants access to control Terminal"** — click **Allow**. (You can change this later in System Settings → Privacy & Security → Automation.) Because the build is ad-hoc signed, macOS may ask again after you rebuild.

Launch at Login is off by default; turn it on (or off again) from the right-click menu.

## Usage

| Action | Result |
|---|---|
| Click the grid icon | Tile all agent windows and bring them to the front |
| Click it again | Hide Terminal, return to the previous app |
| Right-click | Version, **Launch at Login**, **Quit** |
| `AgentGrid.app/Contents/MacOS/AgentGrid --show` | Tile once from the shell (handy for a Shortcuts / keyboard hotkey) |

## How it works

1. `ps -axo tty=,args=` finds the TTYs running an agent CLI.
2. AppleScript asks Terminal for every window's tabs and their TTYs, and picks the windows that host an agent (selecting the agent's tab).
3. The visible screen area (minus menu bar and Dock) is split into the grid, and each window is moved with `set bounds` and raised.

Pure logic lives in [`Layout.swift`](Sources/AgentGrid/Layout.swift) and is covered by `./build.sh test`.

## Limitations

- Terminal.app only for now (iTerm2, Ghostty, WezTerm etc. are not supported yet).
- Uses the main display.

## See also

- [**claude-code-broadcast**](https://github.com/BaldwinFourth/claude-code-broadcast), by the same author: a Claude Code skill that tells every running session to finish its work while you're away, applies only reversible decisions, and leaves you one morning page. It also runs locally, with no telemetry.

## License

[MIT](LICENSE)
