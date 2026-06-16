import AppKit

/// Handles app lifecycle. The only job here is making sure we never leave the
/// machine unable to sleep after Amped quits.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillTerminate(_ notification: Notification) {
        // applicationWillTerminate is delivered on the main thread.
        MainActor.assumeIsolated {
            SleepController.shared.cleanup()
        }
    }
}
