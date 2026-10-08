import Foundation
import Combine
import CoreGraphics
import IOKit.pwr_mgt
import WidgetKit

@MainActor
final class SleepController: ObservableObject {
    static let shared = SleepController()

    @Published private(set) var keepAwake = false {
        didSet { mirrorControlState() }
    }

    @Published private(set) var lidClosed = false {
        didSet { mirrorControlState() }
    }

    @Published private(set) var autoOff: Bool {
        didSet { mirrorControlState() }
    }

    @Published private(set) var helperEnabled: Bool = HelperClient.shared.isEnabled

    @Published private(set) var launchAtLogin: Bool = LoginItem.isEnabled

    @Published private(set) var batteryPercent: Int?
    @Published private(set) var onBattery = false

    private let systemAssertion = PowerAssertion(type: kIOPMAssertionTypePreventUserIdleSystemSleep)
    private let displayAssertion = PowerAssertion(type: kIOPMAssertionTypePreventUserIdleDisplaySleep)
    private let lidMonitor = LidMonitor()
    private var batteryTimer: Timer?

    private static let autoOffKey = "autoOffEnabled"
    private static let helperPromptedKey = "helperPrompted"
    private static let lastKeepAwakeKey = "lastActiveKeepAwake"
    private static let lastLidClosedKey = "lastActiveLidClosed"
    private let autoOffThreshold = 20

    private var helperPrompted: Bool {
        get { UserDefaults.standard.bool(forKey: Self.helperPromptedKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.helperPromptedKey) }
    }

    private init() {
        UserDefaults.standard.register(defaults: [Self.lastKeepAwakeKey: true])
        autoOff = UserDefaults.standard.bool(forKey: Self.autoOffKey)
        refreshBattery()
        batteryTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        lidMonitor.start { [weak self] in
            MainActor.assumeIsolated { self?.handleLidClosed() }
        }
        mirrorControlState()
    }

    func setKeepAwake(_ on: Bool) {
        keepAwake = on
        syncAssertion()
        if on { rememberActiveCombination() }
    }

    func setActive(_ on: Bool) {
        guard on else {
            keepAwake = false
            if lidClosed { setLidClosed(false) } else { syncAssertion() }
            return
        }
        let restoreKeepAwake = UserDefaults.standard.bool(forKey: Self.lastKeepAwakeKey)
        let restoreLidClosed = UserDefaults.standard.bool(forKey: Self.lastLidClosedKey)
        keepAwake = restoreKeepAwake
        syncAssertion()
        if restoreLidClosed { setLidClosed(true) }
    }

    private func rememberActiveCombination() {
        UserDefaults.standard.set(keepAwake, forKey: Self.lastKeepAwakeKey)
        UserDefaults.standard.set(lidClosed, forKey: Self.lastLidClosedKey)
    }

    private func mirrorControlState() {
        let group = UserDefaults(suiteName: AmpedDefaults.suiteName)
        group?.set(keepAwake || lidClosed, forKey: AmpedDefaults.isActiveKey)
        group?.set(lidClosed, forKey: AmpedDefaults.lidClosedKey)
        group?.set(autoOff, forKey: AmpedDefaults.autoOffKey)
        ControlCenter.shared.reloadAllControls()
    }

    func setLidClosed(_ on: Bool) {
        guard on else {
            _ = Privileged.setDisableSleep(false)
            lidClosed = false
            syncAssertion()
            return
        }

        refreshHelper()

        if !helperEnabled && !helperPrompted {
            switch Prompts.offerHelperSetup() {
            case .cancel:
                return
            case .setUpHelper:
                setUpHelper()
                // Not marked prompted, so the offer reappears until the daemon is approved.
                return
            case .justThisTime:
                helperPrompted = true
            }
        }

        if Privileged.setDisableSleep(true) {
            lidClosed = true
            syncAssertion()
            rememberActiveCombination()
        }
    }

    // Lid-closed needs the system assertion too: a shut lid under disablesleep still idle-sleeps without it.
    private func syncAssertion() {
        if keepAwake || lidClosed {
            systemAssertion.enable()
        } else {
            systemAssertion.disable()
        }
        if keepAwake {
            displayAssertion.enable()
        } else {
            displayAssertion.disable()
        }
    }

    func setAutoOff(_ on: Bool) {
        autoOff = on
        UserDefaults.standard.set(on, forKey: Self.autoOffKey)
        if on { tick() }
    }

    private func handleLidClosed() {
        guard lidClosed else { return }
        var count: UInt32 = 0
        CGGetActiveDisplayList(0, nil, &count)
        var displays = [CGDirectDisplayID](repeating: 0, count: Int(count))
        CGGetActiveDisplayList(count, &displays, &count)
        guard displays.allSatisfy({ CGDisplayIsBuiltin($0) != 0 }) else { return }
        ScreenLock.lock()
        _ = try? Process.run(URL(fileURLWithPath: "/usr/bin/pmset"), arguments: ["displaysleepnow"])
    }

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

    private func tick() {
        refreshBattery()
        refreshHelper()
        guard autoOff, onBattery, let percent = batteryPercent, percent <= autoOffThreshold else { return }
        guard keepAwake || lidClosed else { return }

        systemAssertion.disable()
        displayAssertion.disable()
        // Without the helper, clamshell mode can't be dropped unattended.
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

    func cleanup() {
        lidMonitor.stop()
        systemAssertion.disable()
        displayAssertion.disable()
        if lidClosed { _ = Privileged.setDisableSleep(false) }
        keepAwake = false
        lidClosed = false
    }

    var menuBarSymbolName: String {
        if lidClosed { return "pills.fill" }
        if keepAwake { return "pill.fill" }
        return "pill"
    }

    var statusText: String {
        let battery = batteryPercent.map { " · \($0)%" } ?? ""
        if lidClosed { return "Awake — keeps running while locked\(battery)" }
        if keepAwake { return "Awake\(battery)" }
        return "Sleep allowed\(battery)"
    }
}
