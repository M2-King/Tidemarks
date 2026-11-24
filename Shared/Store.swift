import Foundation

/// Days are saved as JSON. The widget reads them from the App Group when the signature has one,
/// otherwise from the shared keychain.
enum Store {
    static let groupID = "group.com.tidemark.shared"

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
