import Foundation
import Security

/// Helpers for locking the XPC channel to our own Developer ID team, so only
/// Amped's signed app can talk to the root helper (and vice-versa).
enum CodeSigning {
    /// The current process's Team Identifier, or nil when unsigned / ad-hoc
    /// (i.e. a local debug build — in which case there's no team to pin to).
    static func currentTeamIdentifier() -> String? {
        var code: SecCode?
        guard SecCodeCopySelf(SecCSFlags(), &code) == errSecSuccess, let code else { return nil }
        var staticCode: SecStaticCode?
        guard SecCodeCopyStaticCode(code, SecCSFlags(), &staticCode) == errSecSuccess, let staticCode else { return nil }
        var info: CFDictionary?
        guard SecCodeCopySigningInformation(staticCode, SecCSFlags(rawValue: kSecCSSigningInformation), &info) == errSecSuccess,
              let dict = info as? [String: Any] else { return nil }
        return dict[kSecCodeInfoTeamIdentifier as String] as? String
    }

    /// A requirement matching a sibling binary with `identifier`, signed by the
    /// same team via Apple's anchor. Returns nil when unsigned (local builds),
    /// in which case callers skip pinning — the helper won't run there anyway.
    static func sameTeamRequirement(identifier: String) -> String? {
        guard let team = currentTeamIdentifier() else { return nil }
        return "anchor apple generic and identifier \"\(identifier)\" and certificate leaf[subject.OU] = \"\(team)\""
    }
}
