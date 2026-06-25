import Foundation

/// Locks the screen while leaving the Mac running. Locking is independent of
/// sleep: our power assertion stays held, so the Mac remains awake — just
/// secured behind a password.
///
/// macOS ships no public "lock now" API (and the old `CGSession -suspend` binary
/// was removed in recent releases), so the primary path calls
/// `SACLockScreenImmediate` from the private `login.framework` — the same routine
/// the Apple-menu "Lock Screen" item uses. It needs no admin rights or
/// entitlements; `dlopen`ing a system framework is permitted under the hardened
/// runtime.
///
/// If that private symbol ever stops resolving (a future macOS, or an
/// App-Store-sandboxed build that can't use private APIs), we fall back to
/// `pmset displaysleepnow`. That only forces the display to sleep — it locks just
/// if the user has "require password after sleep" set — so it's weaker, but a safe
/// degradation rather than silently failing to lock.
enum ScreenLock {
    private typealias LockFn = @convention(c) () -> Void

    /// Resolved once and cached for the process lifetime. The handle is
    /// intentionally never closed.
    private static let lockFn: LockFn? = {
        let path = "/System/Library/PrivateFrameworks/login.framework/Versions/Current/login"
        guard let handle = dlopen(path, RTLD_LAZY),
              let symbol = dlsym(handle, "SACLockScreenImmediate") else { return nil }
        return unsafeBitCast(symbol, to: LockFn.self)
    }()

    /// Returns false only if neither the private symbol nor the fallback worked.
    @discardableResult
    static func lock() -> Bool {
        if let lockFn {
            lockFn()
            return true
        }
        return forceDisplaySleep()
    }

    /// Fallback: `pmset displaysleepnow` needs no privileges and locks when the
    /// user requires a password after sleep.
    private static func forceDisplaySleep() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["displaysleepnow"]
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
}
