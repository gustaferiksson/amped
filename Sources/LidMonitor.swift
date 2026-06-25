import Foundation
import IOKit
import IOKit.pwr_mgt

/// Watches the laptop lid (clamshell) and fires `onClose` the instant it shuts.
///
/// macOS reports lid open/close as a `kIOPMMessageClamshellStateChange` message
/// on the system-power notification stream. We register for that stream and read
/// the "closed" bit out of the message argument. Crucially this still fires while
/// `pmset disablesleep` is on — the case we care about, since that's exactly when
/// a shut lid would otherwise leave the Mac awake *and* unlocked.
final class LidMonitor {
    private var rootPort: io_connect_t = 0
    private var notificationPort: IONotificationPortRef?
    private var notifier: io_object_t = 0
    private var handler: (() -> Void)?

    /// Swift can't import the `iokit_family_msg` macro that defines
    /// `kIOPMMessageClamshellStateChange`, so reconstruct its value the same way:
    /// sys_iokit | sub_iokit_powermanagement | 0x100.
    private static let clamshellStateChange: UInt32 = {
        let sysIOKit: UInt32 = 0x38 << 26
        let subPowerManagement: UInt32 = 0x7 << 14
        let clamshellMessage: UInt32 = 0x100
        return sysIOKit | subPowerManagement | clamshellMessage
    }()

    /// Low bit of the message argument: the clamshell is currently closed.
    private static let clamshellClosedBit: UInt = 1 << 0

    func start(onClose: @escaping () -> Void) {
        guard notificationPort == nil else { return }
        handler = onClose

        let context = Unmanaged.passUnretained(self).toOpaque()
        rootPort = IORegisterForSystemPower(
            context,
            &notificationPort,
            { refcon, _, messageType, messageArgument in
                guard messageType == LidMonitor.clamshellStateChange, let refcon else { return }
                let closed = (UInt(bitPattern: messageArgument) & LidMonitor.clamshellClosedBit) != 0
                guard closed else { return }
                Unmanaged<LidMonitor>.fromOpaque(refcon).takeUnretainedValue().handler?()
            },
            &notifier
        )

        guard rootPort != 0, let notificationPort else { return }
        CFRunLoopAddSource(
            CFRunLoopGetMain(),
            IONotificationPortGetRunLoopSource(notificationPort).takeUnretainedValue(),
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
            IODeregisterForSystemPower(&notifier)
            notifier = 0
        }
        IONotificationPortDestroy(notificationPort)
        self.notificationPort = nil
        if rootPort != 0 {
            IOServiceClose(rootPort)
            rootPort = 0
        }
        handler = nil
    }
}
