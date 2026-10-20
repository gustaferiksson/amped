import SwiftUI

enum SettingsTab: String {
    case general, sleep, about
}

struct SettingsView: View {
    static let showMenuBarItemKey = "showMenuBarItem"
    static let store: UserDefaults = {
#if DEBUG
        if SettingsSnapshot.output != nil {
            let suite = "dev.gustaf.Amped.snapshot"
            UserDefaults.standard.removePersistentDomain(forName: suite)
            return UserDefaults(suiteName: suite) ?? .standard
        }
#endif
        return .standard
    }()

    @ObservedObject var controller: SleepController
    @AppStorage("settingsTab", store: SettingsView.store) private var tab = SettingsTab.general

    var body: some View {
        TabView(selection: $tab) {
            Tab("General", systemImage: "gearshape", value: .general) {
                GeneralSettings(controller: controller)
            }
            Tab("Sleep", systemImage: "moon.zzz", value: .sleep) {
                SleepSettings(controller: controller)
            }
            Tab("About", systemImage: "info.circle", value: .about) {
                AboutSettings()
            }
        }
        .frame(width: 500)
        .onAppear {
            // An accessory app owns nothing in the menu bar, so a Space switch leaves it blank; a Dock icon while Settings is open fixes that.
#if DEBUG
            if SettingsSnapshot.output != nil { NSApp.activate(); return }
#endif
            NSApp.setActivationPolicy(.regular)
            NSApp.activate()
        }
        .onDisappear { NSApp.setActivationPolicy(.accessory) }
    }
}
