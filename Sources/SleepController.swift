import Foundation
import Combine

/// The single source of truth for Amped. Owns the power assertion, the
/// clamshell (lid-closed) state, battery polling and the auto-off safety net.
@MainActor
final class SleepController: ObservableObject {
    static let shared = SleepController()

    /// Prevent idle sleep. Backed by an IOKit power assertion. Independent of
    /// `lidClosed`: it reflects only the user's explicit "keep awake" intent.
    @Published private(set) var keepAwake = false

    /// Also stay awake with the lid closed. Backed by `pmset disablesleep`, run
    /// either by the privileged helper (silent) or a one-off admin prompt.
    /// Independent toggle: enabling it no longer flips `keepAwake`. The idle
    /// assertion it still requires is held internally via `syncAssertion()`.
    @Published private(set) var lidClosed = false

    /// Persisted preference: automatically release everything at a low battery.
    @Published private(set) var autoOff: Bool

    /// Persisted preference (default on): lock the screen the moment the lid
    /// shuts while lid-closed mode is keeping the Mac awake. Without it, a closed
    /// lid would leave the Mac running *and* unlocked. See `handleLidClosed()`.
    @Published private(set) var lockOnLidClose: Bool

    /// Whether the approved root helper is active (lid mode becomes passwordless).
    @Published private(set) var helperEnabled: Bool = HelperClient.shared.isEnabled

    /// Whether Amped is registered to launch at login (reflects SMAppService).
    @Published private(set) var launchAtLogin: Bool = LoginItem.isEnabled

    @Published private(set) var batteryPercent: Int?
    @Published private(set) var onBattery = false

    private let assertion = PowerAssertion()
    private let lidMonitor = LidMonitor()
    private var batteryTimer: Timer?

    private static let autoOffKey = "autoOffEnabled"
    private static let lockOnLidCloseKey = "lockOnLidClose"
    private static let helperPromptedKey = "helperPrompted"
    private let autoOffThreshold = 20

    /// Whether we've already offered the one-time helper setup (so we don't nag).
    private var helperPrompted: Bool {
        get { UserDefaults.standard.bool(forKey: Self.helperPromptedKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.helperPromptedKey) }
    }

    private init() {
        // Lock-on-lid-close defaults to on so lid mode is secure out of the box.
        UserDefaults.standard.register(defaults: [Self.lockOnLidCloseKey: true])
        autoOff = UserDefaults.standard.bool(forKey: Self.autoOffKey)
        lockOnLidClose = UserDefaults.standard.bool(forKey: Self.lockOnLidCloseKey)
        refreshBattery()
        batteryTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        lidMonitor.start { [weak self] in
            MainActor.assumeIsolated { self?.handleLidClosed() }
        }
    }

    // MARK: - Toggles

    func setKeepAwake(_ on: Bool) {
        keepAwake = on
        syncAssertion()
    }

    func setLidClosed(_ on: Bool) {
        guard on else {
            _ = Privileged.setDisableSleep(false)
            lidClosed = false
            syncAssertion() // keep the assertion only if keepAwake still wants it
            return
        }

        refreshHelper()

        // First time without the helper: offer to set it up (passwordless), or
        // fall back to a one-off admin prompt.
        if !helperEnabled && !helperPrompted {
            switch Prompts.offerHelperSetup() {
            case .cancel:
                return
            case .setUpHelper:
                setUpHelper()
                // The daemon must be approved in System Settings before it can
                // run, so we can't finish enabling lid mode now — the user flips
                // it again once approved and it's silent. Deliberately NOT marked
                // "prompted", so the offer reappears until the helper is live.
                return
            case .justThisTime:
                helperPrompted = true // deliberate decline — don't offer again
                // Falls through to the admin-prompt fallback below.
            }
        }

        if Privileged.setDisableSleep(true) {
            lidClosed = true
            syncAssertion() // lid-closed needs the idle assertion held too
        }
    }

    /// The idle-sleep assertion must be held whenever either intent is on:
    /// keep-awake directly, and lid-closed because a clamshell-shut Mac with no
    /// assertion would still fall into ordinary idle sleep. `enable()`/`disable()`
    /// are idempotent, so this is safe to call after any toggle.
    private func syncAssertion() {
        if keepAwake || lidClosed {
            assertion.enable()
        } else {
            assertion.disable()
        }
    }

    func setAutoOff(_ on: Bool) {
        autoOff = on
        UserDefaults.standard.set(on, forKey: Self.autoOffKey)
        if on { tick() }
    }

    func setLockOnLidClose(_ on: Bool) {
        lockOnLidClose = on
        UserDefaults.standard.set(on, forKey: Self.lockOnLidCloseKey)
    }

    /// Fired by `LidMonitor` the instant the lid shuts. Only lock when we're the
    /// reason the Mac is staying awake (lid-closed mode) and the user wants it:
    /// with lid mode off, a shut lid just sleeps and macOS locks on wake as usual.
    private func handleLidClosed() {
        guard lidClosed, lockOnLidClose else { return }
        ScreenLock.lock()
    }

    /// Registers the helper daemon and, if it needs the one-time approval,
    /// opens System Settings and explains. (Remove it later from there.)
    private func setUpHelper() {
        _ = HelperClient.shared.register()
        refreshHelper()
        if !helperEnabled {
            HelperClient.shared.openSettings()
            Prompts.explainHelperApproval()
        }
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
        refreshHelper()
        guard autoOff, onBattery, let percent = batteryPercent, percent <= autoOffThreshold else { return }
        guard keepAwake || lidClosed else { return }

        assertion.disable()
        // With the helper this is silent even with the lid shut; without it we
        // can't drop clamshell mode unattended.
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

    private func refreshHelper() {
        helperEnabled = HelperClient.shared.isEnabled
    }

    // MARK: - Lifecycle

    func cleanup() {
        lidMonitor.stop()
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
