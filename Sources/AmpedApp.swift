import SwiftUI

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
