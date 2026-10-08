import Foundation

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
