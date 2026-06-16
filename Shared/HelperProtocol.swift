import Foundation

/// The XPC contract between the app and the privileged helper. Compiled into
/// both targets. Deliberately minimal — the helper can do exactly one thing.
@objc protocol HelperProtocol {
    func setDisableSleep(_ enabled: Bool, withReply reply: @escaping (Bool) -> Void)
}
