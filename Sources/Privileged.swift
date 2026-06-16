import Foundation

/// Flips the system `disablesleep` flag — the only thing that overrides
/// clamshell (lid-closed) sleep. Prefers the approved root helper (silent); if
/// it isn't set up (e.g. an unsigned local build) it falls back to a one-off
/// native admin prompt.
enum Privileged {
    @discardableResult
    static func setDisableSleep(_ enabled: Bool, allowPrompt: Bool = true) -> Bool {
        if HelperClient.shared.isEnabled, HelperClient.shared.setDisableSleep(enabled) {
            return true
        }
        guard allowPrompt else { return false }
        let value = enabled ? "1" : "0"
        return runAdmin("/usr/bin/pmset -a disablesleep \(value)")
    }

    /// Native "Amped wants to make changes" admin prompt via AppleScript.
    private static func runAdmin(_ command: String) -> Bool {
        let source = "do shell script \"\(command)\" with administrator privileges"
        guard let script = NSAppleScript(source: source) else { return false }
        var error: NSDictionary?
        script.executeAndReturnError(&error)
        return error == nil
    }
}
