import Foundation

struct LunarSpec: Codable, Hashable {
    var y: Int
    var m: Int
    var d: Int
    var leap: Bool
}

struct DayEvent: Codable, Identifiable, Hashable {
    var id: String
    var title: String
    var date: String            // yyyy-MM-dd, Gregorian
    var cal: String             // "solar" or "lunar"
    var lunar: LunarSpec?
    var pinned: Bool
    var includeStart: Bool
    var remind: String          // none, 0, 1, 3, 7, milestone
    var remindTime: String      // HH:mm
    var created: Double

    init(id: String = UUID().uuidString, title: String = "", date: String = Days.iso(Days.today()), cal: String = "solar",
         lunar: LunarSpec? = nil, pinned: Bool = false, includeStart: Bool = false, remind: String = "none",
         remindTime: String = "09:00", created: Double = Date().timeIntervalSince1970) {
        self.id = id; self.title = title; self.date = date; self.cal = cal; self.lunar = lunar; self.pinned = pinned
        self.includeStart = includeStart; self.remind = remind; self.remindTime = remindTime; self.created = created
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
        date = try c.decodeIfPresent(String.self, forKey: .date) ?? Days.iso(Days.today())
        cal = try c.decodeIfPresent(String.self, forKey: .cal) ?? "solar"
        lunar = try c.decodeIfPresent(LunarSpec.self, forKey: .lunar)
        pinned = try c.decodeIfPresent(Bool.self, forKey: .pinned) ?? false
        includeStart = try c.decodeIfPresent(Bool.self, forKey: .includeStart) ?? false
        remind = try c.decodeIfPresent(String.self, forKey: .remind) ?? "none"
        remindTime = try c.decodeIfPresent(String.self, forKey: .remindTime) ?? "09:00"
        created = try c.decodeIfPresent(Double.self, forKey: .created) ?? 0
    }

    var dayNum: Int { Days.parse(date) }
}

enum DayState { case future, today, past }

struct DayInfo {
    let n: Int
    let diff: Int
    let state: DayState
    let count: Int

    init(_ ev: DayEvent, today: Int) {
        n = ev.dayNum
        diff = n - today
        state = diff > 0 ? .future : diff == 0 ? .today : .past
        count = state == .past ? -diff + (ev.includeStart ? 1 : 0) : diff
    }
}
