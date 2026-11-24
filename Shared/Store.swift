import Foundation

/// Days are saved as JSON. The widget reads them from the App Group when the signature has one,
/// otherwise from the shared keychain.
enum Store {
    static let defaultGroupID = "group.com.tidemark.shared"

    /// Signing tools often replace the App Group with the certificate's own one, so read the real one
    /// from the embedded provisioning profile (the widget falls back to the containing app's profile).
    static let groupID: String = {
        let groups = provisionedGroups()
        return groups.first { FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: $0) != nil }
            ?? groups.first ?? defaultGroupID
    }()

    static func provisionedGroups() -> [String] {
        let here = Bundle.main.bundleURL
        let candidates = [
            here.appendingPathComponent("embedded.mobileprovision"),
            here.deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("embedded.mobileprovision")
        ]
        for url in candidates {
            guard let data = try? Data(contentsOf: url),
                  let start = data.range(of: Data("<?xml".utf8)),
                  let end = data.range(of: Data("</plist>".utf8), in: start.upperBound..<data.endIndex),
                  let plist = try? PropertyListSerialization.propertyList(from: data.subdata(in: start.lowerBound..<end.upperBound), format: nil) as? [String: Any],
                  let ent = plist["Entitlements"] as? [String: Any],
                  let groups = ent["com.apple.security.application-groups"] as? [String], !groups.isEmpty
            else { continue }
            return groups.filter { !$0.contains("*") }
        }
        return []
    }

    enum ShareMode { case appGroup, keychain, none }

    static var sharedContainerAvailable: Bool {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) != nil
    }

    static var shareMode: ShareMode {
        if sharedContainerAvailable { return .appGroup }
        return SharedKeychain.read() != nil ? .keychain : .none
    }

    /// Language chosen in the app, for a widget that can't read the App Group's preferences.
    static let sharedLanguage: String? = SharedKeychain.read()?.language

    private static var fileURL: URL {
        let base = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID)
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("events.json")
    }

    static func load() -> [DayEvent]? {
        if sharedContainerAvailable, let e = loadFile() { return e }
        if let p = SharedKeychain.read() { return p.events }
        return loadFile()
    }

    static func save(_ events: [DayEvent]) {
        saveFile(events)
        SharedKeychain.write(.init(events: events, language: Prefs.defaults.string(forKey: "language")))
    }

    private struct Wrap: Codable {
        var version = 1
        var events: [DayEvent]
    }

    private static func loadFile() -> [DayEvent]? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        if let w = try? JSONDecoder().decode(Wrap.self, from: data) { return w.events }
        return try? JSONDecoder().decode([DayEvent].self, from: data)
    }

    private static func saveFile(_ events: [DayEvent]) {
        guard let data = try? JSONEncoder().encode(Wrap(events: events)) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
