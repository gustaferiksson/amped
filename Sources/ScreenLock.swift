import Foundation

// No public lock-now API; SACLockScreenImmediate is what the Apple-menu Lock Screen item calls.
enum ScreenLock {
    private typealias LockFn = @convention(c) () -> Void

    private static let lockFn: LockFn? = {
        let path = "/System/Library/PrivateFrameworks/login.framework/Versions/Current/login"
        guard let handle = dlopen(path, RTLD_LAZY),
              let symbol = dlsym(handle, "SACLockScreenImmediate") else { return nil }
        return unsafeBitCast(symbol, to: LockFn.self)
    }()

    @discardableResult
    static func lock() -> Bool {
        guard let lockFn else { return false }
        lockFn()
        return true
    }
}
