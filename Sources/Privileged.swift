import Foundation

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

    private static func runAdmin(_ command: String) -> Bool {
        let source = "do shell script \"\(command)\" with administrator privileges"
        guard let script = NSAppleScript(source: source) else { return false }
        var error: NSDictionary?
        script.executeAndReturnError(&error)
        return error == nil
    }
}
