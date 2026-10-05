import Foundation
import IOKit
import IOKit.pwr_mgt

/// Watches the laptop lid (clamshell) and fires `onClose` the instant it shuts.
///
/// IOPMrootDomain sends `kIOPMMessageClamshellStateChange` only to general-interest
/// clients; `IORegisterForSystemPower` subscribes to app power-state interest and
/// never receives it. This still fires while `pmset disablesleep` is on.
final class LidMonitor {
    private var notificationPort: IONotificationPortRef?
    private var notifier: io_object_t = 0
    private var handler: (() -> Void)?

    /// Swift can't import the `iokit_family_msg` macro that defines
    /// `kIOPMMessageClamshellStateChange`, so reconstruct its value the same way:
    /// sys_iokit | sub_iokit_powermanagement | 0x100.
    private static let clamshellStateChange: UInt32 = {
        let sysIOKit: UInt32 = 0x38 << 26
        let subPowerManagement: UInt32 = 0xD << 14
        let clamshellMessage: UInt32 = 0x100
        return sysIOKit | subPowerManagement | clamshellMessage
    }()

    /// Low bit of the message argument: the clamshell is currently closed.
    private static let clamshellClosedBit: UInt = 1 << 0

    func start(onClose: @escaping () -> Void) {
        guard notificationPort == nil else { return }
        let rootDomain = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPMrootDomain"))
        guard rootDomain != 0, let port = IONotificationPortCreate(kIOMainPortDefault) else { return }
        defer { IOObjectRelease(rootDomain) }

        let result = IOServiceAddInterestNotification(
            port,
            rootDomain,
            kIOGeneralInterest,
            { refcon, _, messageType, messageArgument in
                guard messageType == LidMonitor.clamshellStateChange, let refcon else { return }
                let closed = (UInt(bitPattern: messageArgument) & LidMonitor.clamshellClosedBit) != 0
                guard closed else { return }
                Unmanaged<LidMonitor>.fromOpaque(refcon).takeUnretainedValue().handler?()
            },
            Unmanaged.passUnretained(self).toOpaque(),
            &notifier
        )
        guard result == KERN_SUCCESS else {
            IONotificationPortDestroy(port)
            return
        }

        handler = onClose
        notificationPort = port
        CFRunLoopAddSource(
            CFRunLoopGetMain(),
            IONotificationPortGetRunLoopSource(port).takeUnretainedValue(),
            .commonModes
        )
    }

    func stop() {
        guard let notificationPort else { return }
        CFRunLoopRemoveSource(
            CFRunLoopGetMain(),
            IONotificationPortGetRunLoopSource(notificationPort).takeUnretainedValue(),
            .commonModes
        )
        if notifier != 0 {
            IOObjectRelease(notifier)
            notifier = 0
        }
        IONotificationPortDestroy(notificationPort)
        self.notificationPort = nil
        handler = nil
    }
}
