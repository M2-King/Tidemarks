import Foundation

/// Days are stored as JSON in the App Group container so the widget can read them.
enum Store {
    static let groupID = "group.com.tidemark.shared"

    static var sharedContainerAvailable: Bool {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) != nil
    }

    static var fileURL: URL {
        let base = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID)
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("events.json")
    }

    static func load() -> [DayEvent]? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        struct Wrap: Codable { var events: [DayEvent] }
        if let w = try? JSONDecoder().decode(Wrap.self, from: data) { return w.events }
        return try? JSONDecoder().decode([DayEvent].self, from: data)
    }

    static func save(_ events: [DayEvent]) {
        struct Wrap: Codable { var version = 1; var events: [DayEvent] }
        guard let data = try? JSONEncoder().encode(Wrap(events: events)) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
