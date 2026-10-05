import SwiftUI

/// Amped — a native macOS menu bar app that keeps your Mac awake.
///
/// An Amphetamine-style alternative that, unlike caffeinate-only tools, can also
/// keep the Mac awake with the lid closed by toggling the system `disablesleep`
/// power setting.
@main
struct AmpedApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var controller = SleepController.shared
    @AppStorage(SettingsView.showMenuBarItemKey, store: SettingsView.store) private var showMenuBarItem = true

    var body: some Scene {
        MenuBarExtra(isInserted: $showMenuBarItem) {
            MenuContent(controller: controller)
        } label: {
            MenuBarLabel(controller: controller)
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView(controller: controller)
        }
    }
}
