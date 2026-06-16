import Foundation
import ServiceManagement

/// App-side interface to the privileged helper: register/unregister the daemon
/// via SMAppService, and call it over a Team-ID-pinned XPC connection.
final class HelperClient {
    static let shared = HelperClient()
    private init() {}

    private var service: SMAppService { SMAppService.daemon(plistName: HelperConstants.plistName) }

    var status: SMAppService.Status { service.status }
    var isEnabled: Bool { service.status == .enabled }

    /// Registers the daemon. macOS may put it in `.requiresApproval` until the
    /// user enables it under Login Items & Extensions.
    @discardableResult
    func register() -> SMAppService.Status {
        try? service.register()
        return service.status
    }

    @discardableResult
    func unregister() -> Bool {
        do { try service.unregister(); return true } catch { return false }
    }

    func openSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }

    /// Asks the root helper to flip `disablesleep`, blocking briefly for the
    /// reply. Returns false if the helper isn't active or the call times out.
    func setDisableSleep(_ enabled: Bool) -> Bool {
        guard isEnabled else { return false }

        let connection = NSXPCConnection(machServiceName: HelperConstants.machServiceName, options: .privileged)
        connection.remoteObjectInterface = NSXPCInterface(with: HelperProtocol.self)
        if let requirement = CodeSigning.sameTeamRequirement(identifier: HelperConstants.helperIdentifier) {
            connection.setCodeSigningRequirement(requirement)
        }
        connection.resume()
        defer { connection.invalidate() }

        let semaphore = DispatchSemaphore(value: 0)
        var result = false
        let proxy = connection.remoteObjectProxyWithErrorHandler { _ in
            semaphore.signal()
        } as? HelperProtocol
        guard let proxy else { return false }

        proxy.setDisableSleep(enabled) { success in
            result = success
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: .now() + 5)
        return result
    }
}
