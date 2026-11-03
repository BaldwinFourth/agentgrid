import AppKit
import ServiceManagement

/// Menu bar button: brings every Terminal window running an AI agent CLI to the front, tiled in an equal grid;
/// a second click hides Terminal and reactivates the previous app (e.g. a game).
@main
final class AgentGridApp: NSObject, NSApplicationDelegate {
    static func main() {
        // `AgentGrid --show`: tile once without the menu bar item and exit (for the shell or a Shortcuts hotkey).
        if CommandLine.arguments.contains("--show") {
            AgentGridApp().show(frontmost: nil)
            exit(0)
        }
        let app = NSApplication.shared
        let delegate = AgentGridApp()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }

    private let terminalBundleID = "com.apple.Terminal"
    private var statusItem: NSStatusItem?
    private var previousApp: NSRunningApplication?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem = item
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "square.grid.2x2", accessibilityDescription: "AgentGrid")
            button.image?.isTemplate = true
            button.toolTip = "Show / hide AI agent sessions (right-click for menu)"
            button.target = self
            button.action = #selector(clicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        if SMAppService.mainApp.status != .enabled { try? SMAppService.mainApp.register() }
    }

    @objc private func clicked() {
        if NSApp.currentEvent?.type == .rightMouseUp { openMenu() } else { toggle() }
    }

    // MARK: show / hide

    private func toggle() {
        let terminal = NSRunningApplication.runningApplications(withBundleIdentifier: terminalBundleID).first
        let frontmost = NSWorkspace.shared.frontmostApplication
        if let terminal, frontmost?.processIdentifier == terminal.processIdentifier {
            hide(terminal)
        } else {
            show(frontmost: frontmost)
        }
    }

    private func hide(_ terminal: NSRunningApplication) {
        terminal.hide()
        if let previousApp, !previousApp.isTerminated { previousApp.activate() }
    }

    fileprivate func show(frontmost: NSRunningApplication?) {
        if let frontmost, frontmost.bundleIdentifier != terminalBundleID, frontmost != NSRunningApplication.current {
            previousApp = frontmost
        }
        guard NSRunningApplication.runningApplications(withBundleIdentifier: terminalBundleID).first != nil else {
            return notify("Terminal is not running.")
        }
        let ttys = agentTTYs(psOutput: run("/bin/ps", ["-axo", "tty=,args="]))
        guard !ttys.isEmpty else { return notify("No AI agent session is running.") }

        guard let listing = runAppleScript(Self.listingScript) else { return }
        let windows = agentWindows(listing: listing, ttys: ttys)
        guard !windows.isEmpty else { return notify("No Terminal window is running an AI agent.") }

        guard let screen = NSScreen.screens.first else { return }
        let visible = screen.visibleFrame
        // AppleScript `bounds` use the main screen's top-left corner as origin, with y growing downward.
        let area = CGRect(x: visible.minX, y: screen.frame.maxY - visible.maxY, width: visible.width, height: visible.height)
        _ = runAppleScript(arrangeScript(windows: windows, cells: gridCells(count: windows.count, in: area)))
    }

    /// One "id:tab:tty" line per Terminal tab. Terminal can also list helper windows that have no id or tabs
    /// (seen after connecting an audio device); reading them raises -1728, so they are skipped instead of
    /// failing the whole listing.
    private static let listingScript = """
    tell application "Terminal"
        set output to ""
        repeat with w in windows
            try
                set wid to id of w
                set i to 0
                repeat with t in tabs of w
                    set i to i + 1
                    set output to output & wid & ":" & i & ":" & (tty of t) & linefeed
                end repeat
            end try
        end repeat
        return output
    end tell
    """

    // MARK: menu

    private func openMenu() {
        let menu = NSMenu()
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        menu.addItem(withTitle: "AgentGrid \(version)", action: nil, keyEquivalent: "")
        menu.addItem(.separator())
        let login = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        login.target = self
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(login)
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }

    @objc private func toggleLaunchAtLogin() {
        if SMAppService.mainApp.status == .enabled {
            try? SMAppService.mainApp.unregister()
        } else {
            try? SMAppService.mainApp.register()
        }
    }

    // MARK: helpers

    private func runAppleScript(_ source: String) -> String? {
        var error: NSDictionary?
        let result = NSAppleScript(source: source)?.executeAndReturnError(&error)
        if let error {
            let code = error[NSAppleScript.errorNumber] as? Int ?? 0
            let message = error[NSAppleScript.errorMessage] as? String ?? "unknown error"
            NSLog("AgentGrid AppleScript error %d: %@", code, message)
            notify(code == -1743
                   ? "No permission to control Terminal: System Settings → Privacy & Security → Automation → AgentGrid → Terminal."
                   : "Terminal script failed (\(code)): \(message)")
            return nil
        }
        return result?.stringValue ?? ""
    }

    private func run(_ path: String, _ arguments: [String]) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do { try process.run() } catch { return "" }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return String(decoding: data, as: UTF8.self)
    }

    private func notify(_ message: String) {
        NSLog("AgentGrid: %@", message)
        NSSound.beep()
        if let button = statusItem?.button {
            button.toolTip = message
            button.appearsDisabled = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { button.appearsDisabled = false }
        }
    }
}
