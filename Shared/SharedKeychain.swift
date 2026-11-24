import Foundation
import Security

/// Shares the days between the app and the widget through the keychain.
/// Works with certificates that have no App Group: wildcard profiles allow keychain groups under the same team (TEAMID.*).
enum SharedKeychain {
    struct Payload: Codable {
        var events: [DayEvent]
        var language: String?
    }

    private static let service = "com.tidemark.shared"
    private static let account = "days"
    private(set) static var lastStatus: OSStatus = 0

    /// The signing team's ID, learned from the access group the system gives a probe item.
    static let teamPrefix: String? = {
        let probe: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.tidemark.probe",
            kSecAttrAccount as String: "probe",
            kSecReturnAttributes as String: true
        ]
        var out: CFTypeRef?
        var status = SecItemCopyMatching(probe as CFDictionary, &out)
        if status == errSecItemNotFound {
            var add = probe
            add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            status = SecItemAdd(add as CFDictionary, &out)
        }
        guard status == errSecSuccess,
              let attrs = out as? [String: Any],
              let group = attrs[kSecAttrAccessGroup as String] as? String,
              let prefix = group.split(separator: ".").first else { return nil }
        return String(prefix)
    }()

    private static func query() -> [String: Any]? {
        guard let team = teamPrefix else { return nil }
        return [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessGroup as String: "\(team).com.tidemark.shared"
        ]
    }

    @discardableResult
    static func write(_ payload: Payload) -> Bool {
        guard var q = query(), let data = try? JSONEncoder().encode(payload) else { return false }
        let attrs: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        var status = SecItemUpdate(q as CFDictionary, attrs as CFDictionary)
        if status == errSecItemNotFound {
            for (k, v) in attrs { q[k] = v }
            status = SecItemAdd(q as CFDictionary, nil)
        }
        lastStatus = status
        return status == errSecSuccess
    }

    static func read() -> Payload? {
        guard var q = query() else { return nil }
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var out: CFTypeRef?
        let status = SecItemCopyMatching(q as CFDictionary, &out)
        lastStatus = status
        guard status == errSecSuccess, let data = out as? Data else { return nil }
        return try? JSONDecoder().decode(Payload.self, from: data)
    }
}
