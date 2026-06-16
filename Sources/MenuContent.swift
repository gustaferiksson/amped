import SwiftUI
import AppKit

/// The dropdown: sleep controls, a couple of preferences, the status, and Quit.
struct MenuContent: View {
    @ObservedObject var controller: SleepController

    var body: some View {
        Toggle("Keep Awake", isOn: Binding(
            get: { controller.keepAwake },
            set: { controller.setKeepAwake($0) }
        ))

        Toggle("Allow Lid Closed", isOn: Binding(
            get: { controller.lidClosed },
            set: { controller.setLidClosed($0) }
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

        Button("Quit Amped") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
