import AppIntents
import SwiftUI
import WidgetKit

@main
struct AmpedControlBundle: WidgetBundle {
    var body: some Widget {
        AmpedToggle()
    }
}

struct AmpedToggle: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: AmpedDefaults.controlKind, provider: Provider()) { isOn in
            ControlWidgetToggle("Amped", isOn: isOn, action: SetAmpedActiveIntent()) { isOn in
                Label(isOn ? "Awake" : "Sleep Allowed", systemImage: isOn ? "pill.fill" : "pill")
            }
        }
        .displayName("Amped")
        .description("Keep your Mac awake with the settings you last used.")
    }

    struct Provider: ControlValueProvider {
        var previewValue: Bool { true }

        func currentValue() async throws -> Bool {
            UserDefaults(suiteName: AmpedDefaults.suiteName)?.bool(forKey: AmpedDefaults.isActiveKey) ?? false
        }
    }
}
