import SwiftUI
import AppKit

/// The dropdown: sleep controls, a couple of preferences, the status, and Quit.
struct MenuContent: View {
    @ObservedObject var controller: SleepController
    @AppStorage(AppUpdater.checksAutomaticallyKey) private var checksForUpdatesAutomatically = true

    var body: some View {
        Toggle("Keep Awake", isOn: Binding(
            get: { controller.keepAwake },
            set: { controller.setKeepAwake($0) }
        ))

        Toggle("Allow Lid Closed", isOn: Binding(
            get: { controller.lidClosed },
            set: { controller.setLidClosed($0) }
        ))

        Toggle("Lock Screen on Lid Close", isOn: Binding(
            get: { controller.lockOnLidClose },
            set: { controller.setLockOnLidClose($0) }
        ))

        Divider()

        Toggle("Auto-off at 20% Battery", isOn: Binding(
            get: { controller.autoOff },
            set: { controller.setAutoOff($0) }
        ))

        Toggle("Launch at Login", isOn: Binding(
            get: { controller.launchAtLogin },
            set: { controller.setLaunchAtLogin($0) }
        ))

        Divider()

        Text(controller.statusText)

        Divider()

        Text(versionLine)

        Toggle("Check for updates automatically", isOn: $checksForUpdatesAutomatically)

        Button("Check for Updates…") {
            AppUpdater.check(manual: true)
        }

        Button("Quit Amped") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }

    /// Local builds carry a `-local` version stamped by `build.sh`, so the user
    /// can tell a working copy apart from an installed release.
    private var versionLine: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        return version.hasSuffix("-local") ? "Amped \(version) — LOCAL BUILD" : "Amped \(version)"
    }
}
