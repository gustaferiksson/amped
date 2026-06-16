import Foundation
import Combine

/// The single source of truth for Amped. Owns the power assertion, the
/// clamshell (lid-closed) state, battery polling and the auto-off safety net.
@MainActor
final class SleepController: ObservableObject {
    static let shared = SleepController()

    /// Prevent idle sleep (the lid is open). Backed by an IOKit power assertion.
    @Published private(set) var keepAwake = false

    /// Also stay awake with the lid closed. Backed by `pmset -a disablesleep 1`,
    /// which is the only thing that overrides clamshell sleep. Implies keepAwake.
    @Published private(set) var lidClosed = false

    /// Persisted preference: automatically release everything at a low battery.
    @Published private(set) var autoOff: Bool

    /// Persisted: whether the passwordless lid-control sudoers rule is installed.
    @Published private(set) var silentMode: Bool

    /// Whether Amped is registered to launch at login (reflects SMAppService).
    @Published private(set) var launchAtLogin: Bool = LoginItem.isEnabled

    @Published private(set) var batteryPercent: Int?
    @Published private(set) var onBattery = false

    private let assertion = PowerAssertion()
    private var batteryTimer: Timer?

    private static let autoOffKey = "autoOffEnabled"
    private static let silentModeKey = "silentModeEnabled"
    private static let silentModePromptedKey = "silentModePrompted"
    private let autoOffThreshold = 20

    /// Whether we've already offered the one-time passwordless setup (so we
    /// don't nag on every lid toggle).
    private var silentModePrompted: Bool {
        get { UserDefaults.standard.bool(forKey: Self.silentModePromptedKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.silentModePromptedKey) }
    }

    private init() {
        autoOff = UserDefaults.standard.bool(forKey: Self.autoOffKey)
        silentMode = UserDefaults.standard.bool(forKey: Self.silentModeKey)
        refreshBattery()
        batteryTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    // MARK: - Toggles

    func setKeepAwake(_ on: Bool) {
        if on {
            keepAwake = true
            assertion.enable()
        } else {
            // Turning off the master toggle also drops clamshell mode.
            if lidClosed { setLidClosed(false) }
            keepAwake = false
            assertion.disable()
        }
    }

    func setLidClosed(_ on: Bool) {
        guard on else {
            // Best effort — we report the user's intent regardless.
            _ = Privileged.setDisableSleep(false)
            lidClosed = false
            return
        }

        // First time only: offer to make this passwordless rather than prompting
        // on every toggle. Installing the rule then makes the pmset call silent,
        // so the whole thing costs a single admin prompt.
        if !silentMode && !silentModePrompted {
            switch Prompts.offerPasswordlessLid() {
            case .cancel:
                return
            case .passwordless:
                silentModePrompted = true
                guard Privileged.enableSilentMode() else { return } // install cancelled → abort
                silentMode = true
                UserDefaults.standard.set(true, forKey: Self.silentModeKey)
            case .justThisTime:
                silentModePrompted = true
            }
        }

        if !keepAwake { setKeepAwake(true) }
        // Silent if the passwordless rule is installed; otherwise the admin prompt.
        if Privileged.setDisableSleep(true) {
            lidClosed = true
        }
    }

    func setAutoOff(_ on: Bool) {
        autoOff = on
        UserDefaults.standard.set(on, forKey: Self.autoOffKey)
        if on { tick() }
    }

    /// One-time setup: install (or remove) a tightly-scoped sudoers rule so the
    /// lid toggle stops asking for a password. Shows a single admin prompt; if
    /// the user cancels, the toggle is left unchanged.
    func setSilentMode(_ on: Bool) {
        let ok = on ? Privileged.enableSilentMode() : Privileged.disableSilentMode()
        guard ok else { return }
        silentMode = on
        UserDefaults.standard.set(on, forKey: Self.silentModeKey)
        // If the rule is removed, allow the one-time offer to appear again later.
        if !on { silentModePrompted = false }
    }

    func setLaunchAtLogin(_ on: Bool) {
        if LoginItem.setEnabled(on) {
            launchAtLogin = on
        } else {
            launchAtLogin = LoginItem.isEnabled
        }
    }

    // MARK: - Battery / auto-off safety net

    private func tick() {
        refreshBattery()
        guard autoOff, onBattery, let percent = batteryPercent, percent <= autoOffThreshold else { return }
        guard keepAwake || lidClosed else { return }

        // Release the idle-sleep assertion immediately — no password needed.
        assertion.disable()
        // Drop clamshell mode without prompting. This succeeds silently only if
        // the optional passwordless setup is installed (see scripts/), which is
        // exactly the case where the lid is shut and nobody can type a password.
        if lidClosed { _ = Privileged.setDisableSleep(false, allowPrompt: false) }
        keepAwake = false
        lidClosed = false
    }

    private func refreshBattery() {
        if let info = Battery.read() {
            batteryPercent = info.percent
            onBattery = info.isOnBattery
        } else {
            batteryPercent = nil
            onBattery = false
        }
    }

    // MARK: - Lifecycle

    func cleanup() {
        assertion.disable()
        if lidClosed { _ = Privileged.setDisableSleep(false) }
    }

    // MARK: - Presentation

    var menuBarSymbolName: String {
        if lidClosed { return "pills.fill" }
        if keepAwake { return "pill.fill" }
        return "pill"
    }

    var statusText: String {
        let battery = batteryPercent.map { " · \($0)%" } ?? ""
        if lidClosed { return "Awake — lid can stay closed\(battery)" }
        if keepAwake { return "Awake\(battery)" }
        return "Sleep allowed\(battery)"
    }
}
