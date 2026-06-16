import Foundation
import IOKit.pwr_mgt

/// Thin wrapper around IOKit power assertions — the same mechanism `caffeinate`
/// uses. Holds both a system-sleep and a display-sleep assertion so the Mac
/// (and its screen) stay awake while the lid is open. No privileges required.
final class PowerAssertion {
    private var ids: [IOPMAssertionID] = []

    var isActive: Bool { !ids.isEmpty }

    func enable(reason: String = "Amped is keeping this Mac awake") {
        guard ids.isEmpty else { return }
        let types = [
            kIOPMAssertionTypePreventUserIdleSystemSleep,
            kIOPMAssertionTypePreventUserIdleDisplaySleep,
        ]
        for type in types {
            var id = IOPMAssertionID(0)
            let result = IOPMAssertionCreateWithName(
                type as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                reason as CFString,
                &id
            )
            if result == kIOReturnSuccess {
                ids.append(id)
            }
        }
    }

    func disable() {
        for id in ids {
            IOPMAssertionRelease(id)
        }
        ids.removeAll()
    }
}
