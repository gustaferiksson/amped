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
            GeneralSettings(controller: controller)
                .tabItem { Label("General", systemImage: "gearshape") }
                .tag(SettingsTab.general)
            SleepSettings(controller: controller)
                .tabItem { Label("Sleep", systemImage: "moon.zzz") }
                .tag(SettingsTab.sleep)
            AboutSettings()
                .tabItem { Label("About", systemImage: "info.circle") }
                .tag(SettingsTab.about)
        }
        .frame(width: 500)
        .onAppear { NSApp.activate() }
    }
}
