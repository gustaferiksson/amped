import AppKit

enum LidSetupChoice {
    case passwordless
    case justThisTime
    case cancel
}

enum Prompts {
    /// One-time offer, shown the first time the user enables lid-closed mode, to
    /// make it passwordless instead of prompting on every toggle.
    @MainActor
    static func offerPasswordlessLid() -> LidSetupChoice {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Stop asking for your password?"
        alert.informativeText = """
        Keeping the Mac awake with the lid closed needs administrator rights. \
        Amped can install a small rule so it never has to ask again — it allows \
        only “pmset disablesleep” on and off, nothing else.

        You'll be asked for your password once now. Turn off “Skip Password for \
        Lid Mode” any time to remove it.
        """
        alert.addButton(withTitle: "Make It Passwordless")
        alert.addButton(withTitle: "Just This Time")
        alert.addButton(withTitle: "Cancel")

        NSApp.activate()
        switch alert.runModal() {
        case .alertFirstButtonReturn: return .passwordless
        case .alertSecondButtonReturn: return .justThisTime
        default: return .cancel
        }
    }
}
