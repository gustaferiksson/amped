import Foundation

/// Locks the screen while leaving the Mac running. Locking is independent of
/// sleep: our power assertion stays held, so the Mac remains awake — just
/// secured behind a password.
///
/// macOS ships no public "lock now" API (and the old `CGSession -suspend` binary
/// was removed in recent releases), so we call `SACLockScreenImmediate` from the
/// private `login.framework` — the same routine the Apple-menu "Lock Screen" item
/// uses. It needs no admin rights or entitlements; `dlopen`ing a system framework
/// is permitted under the hardened runtime.
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

    /// Returns false only if the lock routine couldn't be resolved.
    @discardableResult
    static func lock() -> Bool {
        guard let lockFn else { return false }
        lockFn()
        return true
    }
}
