import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
#if DEBUG
        if let output = SettingsSnapshot.output {
            Task { await SettingsSnapshot.capture(to: output) { _ = applicationShouldHandleReopen(NSApp, hasVisibleWindows: false) } }
            return
        }
#endif
        AppUpdater.registerDefaults()
#if !DEBUG
        if UserDefaults.standard.bool(forKey: AppUpdater.checksAutomaticallyKey) {
            AppUpdater.check(manual: false)
        }
#endif
    }

    func applicationWillTerminate(_ notification: Notification) {
        SleepController.shared.cleanup()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // SwiftUI rejects showSettingsWindow: sent from code ("use SettingsLink") but honours its own app-menu item.
        guard let menu = NSApp.mainMenu?.items.first?.submenu,
              let index = menu.items.firstIndex(where: { $0.keyEquivalent == "," })
        else { return true }
        NSApp.activate()
        menu.performActionForItem(at: index)
        return true
    }
}
