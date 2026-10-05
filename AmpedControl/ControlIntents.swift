import AppIntents

@available(macOS 26, *)
struct SetAmpedActiveIntent: SetValueIntent {
    static let title: LocalizedStringResource = "Keep Mac Awake"
    // A foreground mode cannot run in an extension, so the system runs this in the app, launching it if needed.
    static let supportedModes: IntentModes = .foreground(.dynamic)

    @Parameter(title: "Active")
    var value: Bool

    @MainActor
    func perform() async throws -> some IntentResult {
#if AMPED_CONTROL_EXTENSION
        throw CocoaError(.featureUnsupported)
#else
        SleepController.shared.setActive(value)
#endif
        return .result()
    }
}
