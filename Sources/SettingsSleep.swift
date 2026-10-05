import SwiftUI

struct SleepSettings: View {
    @ObservedObject var controller: SleepController

    var body: some View {
        Form {
            Section {
                Toggle("Keep awake", isOn: Binding(
                    get: { controller.keepAwake },
                    set: { controller.setKeepAwake($0) }
                ))
            } footer: {
                Text("Stops your Mac from sleeping when idle while the lid is open. Always off when Amped starts, and released when it quits.")
            }

            Section {
                Toggle("Keep running while locked", isOn: Binding(
                    get: { controller.lidClosed },
                    set: { controller.setLidClosed($0) }
                ))
            } footer: {
                Text("Keeps your Mac and everything on it running even with the lid closed, and locks the screen and turns it off when you close the lid without an external display. This changes a system power setting, needs Amped’s helper or an administrator password, and Amped turns it back off when it quits.")
            }

            Section {
                Toggle("Auto-off at 20% battery", isOn: Binding(
                    get: { controller.autoOff },
                    set: { controller.setAutoOff($0) }
                ))
            } footer: {
                Text("Turns off keep awake and lid-closed mode when your Mac is on battery power at 20% or less, so it can still sleep before the battery runs out.")
            }
        }
        .formStyle(.grouped)
        .frame(height: 360)
    }
}
