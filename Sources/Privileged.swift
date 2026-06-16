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

    /// Installs a tightly-scoped passwordless sudoers rule so the lid toggle
    /// never needs a password again. Shows ONE admin prompt. The rule permits
    /// only the two exact `pmset disablesleep` commands above — nothing else.
    static func enableSilentMode() -> Bool {
        let user = NSUserName()
        let content = """
        # Installed by Amped — passwordless toggling of clamshell (lid-closed) sleep.
        # Remove with: sudo rm /etc/sudoers.d/amped
        \(user) ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 0, /usr/bin/pmset -a disablesleep 1
        """
        let tmp = (NSTemporaryDirectory() as NSString).appendingPathComponent("amped.sudoers")
        guard (try? content.write(toFile: tmp, atomically: true, encoding: .utf8)) != nil else {
            return false
        }
        defer { try? FileManager.default.removeItem(atPath: tmp) }
        // As root: validate the file, install it with strict perms, validate the
        // installed copy. Any failure in the chain aborts before it takes effect.
        let command = "/usr/sbin/visudo -cf '\(tmp)' && "
            + "/usr/bin/install -m 0440 -o root -g wheel '\(tmp)' /etc/sudoers.d/amped && "
            + "/usr/sbin/visudo -cf /etc/sudoers.d/amped"
        return runAdmin(command)
    }

    /// Removes the passwordless rule installed by `enableSilentMode()`.
    static func disableSilentMode() -> Bool {
        runAdmin("/bin/rm -f /etc/sudoers.d/amped")
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

    /// Native "Amped wants to make changes" admin prompt via AppleScript.
    private static func runAdmin(_ command: String) -> Bool {
        let source = "do shell script \"\(command)\" with administrator privileges"
        guard let script = NSAppleScript(source: source) else { return false }
        var error: NSDictionary?
        script.executeAndReturnError(&error)
        return error == nil
    }
}
