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
                Toggle("Allow lid closed", isOn: Binding(
                    get: { controller.lidClosed },
                    set: { controller.setLidClosed($0) }
                ))
            } footer: {
                Text("Keeps your Mac awake with the lid closed by changing a system power setting. This needs Amped’s helper or an administrator password, and Amped turns it back off when it quits.")
            }

            Section {
                Toggle("Lock screen on lid close", isOn: Binding(
                    get: { controller.lockOnLidClose },
                    set: { controller.setLockOnLidClose($0) }
                ))
            } footer: {
                Text("macOS normally locks when your Mac sleeps. With the lid closed and sleep prevented, Amped locks the screen instead, so your Mac is never left running unlocked.")
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
        .frame(height: 475)
    }
}
