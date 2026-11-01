import CoreGraphics
import Foundation

/// Rows × columns for `n` sessions: 1–3 sit in one row; beyond that ⌈√n⌉ columns (4 → 2×2, 6 → 2×3, 9 → 3×3).
func gridSize(_ n: Int) -> (rows: Int, columns: Int) {
    if n <= 3 { return (1, max(n, 0)) }
    var columns = 1
    while columns * columns < n { columns += 1 }
    return ((n + columns - 1) / columns, columns)
}

/// Cells for `count` windows inside `area` (top-left origin, y grows downward — AppleScript `bounds` convention),
/// left to right, top to bottom. A short last row stretches to fill; edges are rounded so cells never gap or overlap.
func gridCells(count n: Int, in area: CGRect) -> [CGRect] {
    guard n > 0 else { return [] }
    let (rows, columns) = gridSize(n)
    var cells: [CGRect] = []
    for row in 0..<rows {
        let inRow = min(columns, n - row * columns)
        let y0 = area.minY + (area.height * CGFloat(row) / CGFloat(rows)).rounded()
        let y1 = area.minY + (area.height * CGFloat(row + 1) / CGFloat(rows)).rounded()
        for col in 0..<inRow {
            let x0 = area.minX + (area.width * CGFloat(col) / CGFloat(inRow)).rounded()
            let x1 = area.minX + (area.width * CGFloat(col + 1) / CGFloat(inRow)).rounded()
            cells.append(CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0))
        }
    }
    return cells
}

/// Executable names counted as AI agent sessions.
let agentProcessNames: Set<String> = ["claude", "claude.exe", "grok", "agy", "codex", "gemini", "opencode", "aider", "cursor-agent", "qwen"]

/// Script interpreters whose first non-flag argument names the real program (e.g. `node /opt/homebrew/bin/gemini`).
private func isInterpreter(_ name: String) -> Bool {
    ["node", "bun", "deno"].contains(name) || name.hasPrefix("python")
}

private func baseName(_ path: Substring) -> String {
    String(path.split(separator: "/").last ?? path)
}

/// TTY paths ("/dev/ttys000") of terminals running an agent, from `ps -axo tty=,args=` output.
/// Native CLIs match on argv[0]; interpreter-hosted ones on the script name. Processes without a terminal are ignored.
func agentTTYs(psOutput: String) -> Set<String> {
    var result: Set<String> = []
    for line in psOutput.split(separator: "\n") {
        let fields = line.split(separator: " ", omittingEmptySubsequences: true)
        guard fields.count >= 2, fields[0].hasPrefix("tty") else { continue }
        var program = baseName(fields[1])
        if isInterpreter(program), let script = fields.dropFirst(2).first(where: { !$0.hasPrefix("-") }) {
            program = baseName(script)
        }
        if agentProcessNames.contains(program) { result.insert("/dev/" + fields[0]) }
    }
    return result
}

struct WindowPick: Equatable {
    let id: Int
    let tab: Int
}

/// Terminal listing ("id:tab:tty" lines) → windows running an agent. Each window counts once (its first agent tab);
/// ordered by window id, i.e. creation order, so every window lands in the same cell on every press.
func agentWindows(listing: String, ttys: Set<String>) -> [WindowPick] {
    var firstTab: [Int: Int] = [:]
    for line in listing.split(separator: "\n") {
        let parts = line.split(separator: ":", maxSplits: 2)
        guard parts.count == 3, let id = Int(parts[0]), let tab = Int(parts[1]) else { continue }
        let tty = parts[2].trimmingCharacters(in: .whitespaces)
        guard ttys.contains(tty) else { continue }
        if let existing = firstTab[id], existing <= tab { continue }
        firstTab[id] = tab
    }
    return firstTab.keys.sorted().map { WindowPick(id: $0, tab: firstTab[$0]!) }
}

/// AppleScript sent to Terminal: un-minimize, select the agent tab, place in its cell, raise; finally activate Terminal.
func arrangeScript(windows: [WindowPick], cells: [CGRect]) -> String {
    var lines = ["tell application \"Terminal\""]
    for (window, cell) in zip(windows, cells) {
        let w = "window id \(window.id)"
        lines += [
            "set miniaturized of \(w) to false",
            "set selected tab of \(w) to tab \(window.tab) of \(w)",
            "set bounds of \(w) to {\(Int(cell.minX)), \(Int(cell.minY)), \(Int(cell.maxX)), \(Int(cell.maxY))}",
            "set index of \(w) to 1",
        ]
    }
    lines += ["activate", "end tell"]
    return lines.joined(separator: "\n")
}
