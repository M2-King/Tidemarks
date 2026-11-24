import Foundation

/// Whole days since 1970-01-01. Day numbers never shift with time zones or daylight saving.
enum Days {
    static let utc: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    static func num(_ y: Int, _ m: Int, _ d: Int) -> Int {
        let date = utc.date(from: DateComponents(year: y, month: m, day: d)) ?? Date(timeIntervalSince1970: 0)
        return Int((date.timeIntervalSince1970 / 86400).rounded())
    }

    static func ymd(_ n: Int) -> (y: Int, m: Int, d: Int) {
        let c = utc.dateComponents([.year, .month, .day], from: Date(timeIntervalSince1970: Double(n) * 86400))
        return (c.year ?? 1970, c.month ?? 1, c.day ?? 1)
    }

    static func today(_ now: Date = Date()) -> Int {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: now)
        return num(c.year ?? 1970, c.month ?? 1, c.day ?? 1)
    }

    static func parse(_ s: String) -> Int {
        let p = s.split(separator: "-").compactMap { Int($0) }
        guard p.count == 3 else { return today() }
        return num(p[0], p[1], p[2])
    }

    static func iso(_ n: Int) -> String {
        let a = ymd(n)
        return String(format: "%04d-%02d-%02d", a.y, a.m, a.d)
    }

    /// 0 = Sunday
    static func weekday(_ n: Int) -> Int { (((n + 4) % 7) + 7) % 7 }

    static func daysInMonth(_ y: Int, _ m: Int) -> Int {
        let date = utc.date(from: DateComponents(year: y, month: m, day: 1)) ?? Date()
        return utc.range(of: .day, in: .month, for: date)?.count ?? 30
    }

    /// Local wall-clock date for a day number (used by date pickers and notifications).
    static func localDate(_ n: Int, hour: Int = 12, minute: Int = 0) -> Date {
        let a = ymd(n)
        return Calendar.current.date(from: DateComponents(year: a.y, month: a.m, day: a.d, hour: hour, minute: minute)) ?? Date()
    }

    static func fromLocalDate(_ date: Date) -> Int {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return num(c.year ?? 1970, c.month ?? 1, c.day ?? 1)
    }

    /// Calendar difference between two days as years, months, days.
    static func between(_ a: Int, _ b: Int) -> (y: Int, m: Int, d: Int) {
        let lo = min(a, b), hi = max(a, b)
        let A = ymd(lo), B = ymd(hi)
        var y = B.y - A.y, m = B.m - A.m, d = B.d - A.d
        if d < 0 {
            m -= 1
            d += daysInMonth(B.m == 1 ? B.y - 1 : B.y, B.m == 1 ? 12 : B.m - 1)
        }
        if m < 0 { y -= 1; m += 12 }
        return (y, m, d)
    }
}
