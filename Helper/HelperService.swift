import Foundation

/// The privileged work, running as root inside the daemon: flip `disablesleep`.
final class HelperService: NSObject, HelperProtocol {
    func setDisableSleep(_ enabled: Bool, withReply reply: @escaping (Bool) -> Void) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["-a", "disablesleep", enabled ? "1" : "0"]
        do {
            try process.run()
            process.waitUntilExit()
            reply(process.terminationStatus == 0)
        } catch {
            reply(false)
        }
    }
}

/// Accepts XPC connections only from Amped's signed app (same team).
final class HelperListenerDelegate: NSObject, NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
        if let requirement = CodeSigning.sameTeamRequirement(identifier: HelperConstants.appIdentifier) {
            connection.setCodeSigningRequirement(requirement)
        }
        connection.exportedInterface = NSXPCInterface(with: HelperProtocol.self)
        connection.exportedObject = HelperService()
        connection.resume()
        return true
    }
}
