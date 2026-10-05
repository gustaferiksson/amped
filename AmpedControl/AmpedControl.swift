import AppIntents
import SwiftUI
import WidgetKit

@main
struct AmpedControlBundle: WidgetBundle {
    var body: some Widget {
        AmpedToggle()
        LidClosedToggle()
        LockOnLidCloseToggle()
        AutoOffToggle()
    }
}

struct GroupValueProvider: ControlValueProvider {
    let key: String

    var previewValue: Bool { true }

    func currentValue() async throws -> Bool {
        UserDefaults(suiteName: AmpedDefaults.suiteName)?.bool(forKey: key) ?? false
    }
}

struct AmpedToggle: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "dev.gustaf.Amped.toggle", provider: GroupValueProvider(key: AmpedDefaults.isActiveKey)) { isOn in
            ControlWidgetToggle("Amped", isOn: isOn, action: SetAmpedActiveIntent()) { isOn in
                Label(isOn ? "Awake" : "Sleep Allowed", systemImage: isOn ? "pill.fill" : "pill")
            }
        }
        .displayName("Amped")
        .description("Keep your Mac awake with the settings you last used.")
    }
}

struct LidClosedToggle: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "dev.gustaf.Amped.lidClosed", provider: GroupValueProvider(key: AmpedDefaults.lidClosedKey)) { isOn in
            ControlWidgetToggle("Allow Lid Closed", isOn: isOn, action: SetLidClosedIntent()) { isOn in
                Label(isOn ? "On" : "Off", systemImage: "laptopcomputer")
            }
        }
        .displayName("Allow Lid Closed")
        .description("Keep your Mac awake with the lid closed.")
    }
}

struct LockOnLidCloseToggle: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "dev.gustaf.Amped.lockOnLidClose", provider: GroupValueProvider(key: AmpedDefaults.lockOnLidCloseKey)) { isOn in
            ControlWidgetToggle("Lock on Lid Close", isOn: isOn, action: SetLockOnLidCloseIntent()) { isOn in
                Label(isOn ? "On" : "Off", systemImage: isOn ? "lock.fill" : "lock.open")
            }
        }
        .displayName("Lock Screen on Lid Close")
        .description("Lock the screen when the lid closes while Amped keeps the Mac awake.")
    }
}

struct AutoOffToggle: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "dev.gustaf.Amped.autoOff", provider: GroupValueProvider(key: AmpedDefaults.autoOffKey)) { isOn in
            ControlWidgetToggle("Auto-off at 20%", isOn: isOn, action: SetAutoOffIntent()) { isOn in
                Label(isOn ? "On" : "Off", systemImage: "battery.25percent")
            }
        }
        .displayName("Auto-off at 20% Battery")
        .description("Let the Mac sleep again when the battery drops to 20%.")
    }
}
