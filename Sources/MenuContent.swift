import SwiftUI
import AppKit

/// The dropdown. Three toggles, a status line, and Quit — that's the whole app.
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

        Divider()

        Text(controller.statusText)

        Divider()

        Button("Quit Amped") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
