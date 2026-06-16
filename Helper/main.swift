import Foundation

// Entry point for the root LaunchDaemon. Vends the XPC Mach service declared in
// the daemon plist and runs forever, serving the app's requests.
let delegate = HelperListenerDelegate()
let listener = NSXPCListener(machServiceName: HelperConstants.machServiceName)
listener.delegate = delegate
listener.resume()
dispatchMain()
