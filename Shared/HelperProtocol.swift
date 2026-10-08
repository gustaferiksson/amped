import Foundation

@objc protocol HelperProtocol {
    func setDisableSleep(_ enabled: Bool, withReply reply: @escaping (Bool) -> Void)
}
