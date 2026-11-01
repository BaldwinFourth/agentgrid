// Pure-logic tests. Run: ./build.sh test
import Foundation

var failures = 0
func expectEqual<T: Equatable>(_ actual: T, _ expected: T, _ name: String) {
    if actual == expected {
        print("✓ \(name)")
    } else {
        failures += 1
        print("✗ \(name)\n  expected: \(expected)\n  actual:   \(actual)")
    }
}
func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect { CGRect(x: x, y: y, width: w, height: h) }
func at(_ cells: [CGRect], _ i: Int) -> CGRect? { i < cells.count ? cells[i] : nil }

// MARK: grid layout
// Area uses a top-left origin (y grows downward): 1200×600 below a 25 pt menu bar.
let area = rect(0, 25, 1200, 600)

expectEqual(gridCells(count: 0, in: area), [], "0 sessions → no cells")
expectEqual(gridCells(count: 1, in: area), [area], "1 session → whole area")
expectEqual(gridCells(count: 2, in: area), [rect(0, 25, 600, 600), rect(600, 25, 600, 600)], "2 sessions → two halves side by side")
expectEqual(gridCells(count: 3, in: area), [rect(0, 25, 400, 600), rect(400, 25, 400, 600), rect(800, 25, 400, 600)], "3 sessions → three columns")
expectEqual(gridCells(count: 4, in: area), [rect(0, 25, 600, 300), rect(600, 25, 600, 300), rect(0, 325, 600, 300), rect(600, 325, 600, 300)], "4 sessions → 2×2")
expectEqual(gridCells(count: 5, in: area), [rect(0, 25, 400, 300), rect(400, 25, 400, 300), rect(800, 25, 400, 300), rect(0, 325, 600, 300), rect(600, 325, 600, 300)], "5 sessions → 3 on top, 2 wide below")
expectEqual(gridCells(count: 6, in: area).count, 6, "6 sessions → 6 cells")
expectEqual(at(gridCells(count: 6, in: area), 5), rect(800, 325, 400, 300) as CGRect?, "6 sessions → 2 rows × 3 columns, last cell bottom-right")
expectEqual(at(gridCells(count: 9, in: area), 4), rect(400, 225, 400, 200) as CGRect?, "9 sessions → 3×3, center cell")
expectEqual(at(gridCells(count: 10, in: area), 9), rect(600, 425, 600, 200) as CGRect?, "10 sessions → 4+4+2, short last row stretches")
let thirds = gridCells(count: 3, in: rect(0, 0, 1000, 500))
expectEqual(thirds.map(\.width).reduce(0, +), 1000, "3 sessions on 1000 pt → widths sum to exactly 1000")
expectEqual(thirds.last?.maxX ?? -1, 1000, "3 sessions → last cell touches the right edge")

// MARK: agent detection from `ps -axo tty=,args=`
let ps = """
ttys000  /opt/homebrew/lib/node_modules/@anthropic-ai/claude-code/bin/claude.exe --resume abc
ttys001  -zsh
ttys002  /usr/local/bin/grok
ttys003  agy
ttys004  claude
??       /Applications/Claude.app/Contents/MacOS/Claude
ttys005  /usr/bin/claudette
ttys006  node /opt/homebrew/bin/gemini
ttys007  /opt/homebrew/bin/codex
ttys008  node /usr/local/lib/server.js
ttys009  python3 /usr/local/bin/aider --model x
ttys010  vim claude
ttys011  node --no-warnings /opt/homebrew/bin/opencode
"""
expectEqual(agentTTYs(psOutput: ps),
            ["/dev/ttys000", "/dev/ttys002", "/dev/ttys003", "/dev/ttys004", "/dev/ttys006", "/dev/ttys007", "/dev/ttys009", "/dev/ttys011"],
            "ps → agent CLIs (native and node/python scripts); no tty, look-alikes and editors excluded")

// MARK: window selection from Terminal listing ("id:tab:tty")
let listing = """
412:1:/dev/ttys003
88:1:/dev/ttys001
88:2:/dev/ttys000
95:1:/dev/ttys009
300:1:/dev/ttys004
300:2:/dev/ttys002
"""
let picked = agentWindows(listing: listing, ttys: ["/dev/ttys000", "/dev/ttys002", "/dev/ttys003", "/dev/ttys004"])
expectEqual(picked.map(\.id), [88, 300, 412], "agent windows in creation (id) order; window without agent (95) skipped; each window once")
expectEqual(picked.map(\.tab), [2, 1, 1], "first agent tab of each window is selected")

// MARK: AppleScript generation
expectEqual(arrangeScript(windows: [WindowPick(id: 88, tab: 2)], cells: [rect(0, 25, 600, 300)]), """
tell application "Terminal"
set miniaturized of window id 88 to false
set selected tab of window id 88 to tab 2 of window id 88
set bounds of window id 88 to {0, 25, 600, 325}
set index of window id 88 to 1
activate
end tell
""", "arrange script for one window")

print(failures == 0 ? "\nALL PASSED" : "\n\(failures) FAILED")
exit(failures == 0 ? 0 : 1)
