import Foundation

/// User preferences, stored in the App Group so the widget follows them too.
enum Prefs {
    static var defaults: UserDefaults { UserDefaults(suiteName: Store.groupID) ?? .standard }
    static var language: String { defaults.string(forKey: "language") ?? "system" }
    static var defaultRemind: String { defaults.string(forKey: "defaultRemind") ?? "none" }
    static var defaultTime: String { defaults.string(forKey: "defaultTime") ?? "09:00" }
}
