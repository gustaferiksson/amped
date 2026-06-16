import Foundation
import IOKit.ps

struct BatteryInfo {
    let percent: Int
    let isOnBattery: Bool
}

/// Reads the internal battery via IOKit power sources. Returns nil on Macs
/// without a battery (desktops), which simply disables the auto-off feature.
enum Battery {
    static func read() -> BatteryInfo? {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as [CFTypeRef]
        for source in sources {
            guard let desc = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any],
                  let current = desc[kIOPSCurrentCapacityKey] as? Int,
                  let maximum = desc[kIOPSMaxCapacityKey] as? Int,
                  maximum > 0
            else { continue }

            let state = desc[kIOPSPowerSourceStateKey] as? String
            let percent = Int((Double(current) / Double(maximum)) * 100.0)
            return BatteryInfo(percent: percent, isOnBattery: state == kIOPSBatteryPowerValue)
        }
        return nil
    }
}
