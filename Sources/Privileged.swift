import Foundation

/// Runs the one privileged operation Amped needs: flipping the system
/// `disablesleep` flag, which is what keeps the Mac awake with the lid shut.
///
/// It prefers passwordless `sudo` (set up optionally via scripts/enable-silent-mode.sh)
/// and otherwise falls back to a native macOS administrator prompt.
enum Privileged {
    @discardableResult
    static func setDisableSleep(_ enabled: Bool, allowPrompt: Bool = true) -> Bool {
        let value = enabled ? "1" : "0"
        if runSudoNonInteractive(["/usr/bin/pmset", "-a", "disablesleep", value]) {
            return true
        }
        guard allowPrompt else { return false }
        return runAdmin("/usr/bin/pmset -a disablesleep \(value)")
    }

    // MARK: - Helpers

    /// `sudo -n …` — succeeds only when a NOPASSWD sudoers rule is installed.
    private static func runSudoNonInteractive(_ arguments: [String]) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        process.arguments = ["-n"] + arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    /// Native "Lidless wants to make changes" admin prompt via AppleScript.
    private static func runAdmin(_ command: String) -> Bool {
        let source = "do shell script \"\(command)\" with administrator privileges"
        guard let script = NSAppleScript(source: source) else { return false }
        var error: NSDictionary?
        script.executeAndReturnError(&error)
        return error == nil
    }
}
