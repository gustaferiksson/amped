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

    var body: some Scene {
        MenuBarExtra {
            MenuContent(controller: controller)
        } label: {
            MenuBarLabel(controller: controller)
        }
        .menuBarExtraStyle(.menu)
    }
}
