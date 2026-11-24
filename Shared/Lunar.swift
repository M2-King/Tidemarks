import Foundation

/// Chinese lunar calendar, using the system's own Chinese calendar data.
enum Lunar {
    struct Day: Hashable { let y: Int; let m: Int; let d: Int; let leap: Bool }
    struct Month: Hashable { let m: Int; let leap: Bool; let start: Int; let len: Int }

    private static let cal: Calendar = {
        var c = Calendar(identifier: .chinese)
        c.timeZone = TimeZone(identifier: "Asia/Shanghai")!  // lunar months start by China time
        return c
    }()
    private static let lock = NSLock()
    private static var dayCache: [Int: Day] = [:]
    private static var yearCache: [Int: [Month]] = [:]

    static func fromSolar(_ n: Int) -> Day {
        lock.lock(); defer { lock.unlock() }
        return fromSolarLocked(n)
    }

    private static func fromSolarLocked(_ n: Int) -> Day {
        if let hit = dayCache[n] { return hit }
        let date = Date(timeIntervalSince1970: Double(n) * 86400 + 4 * 3600)  // 12:00 in China
        let c = cal.dateComponents([.month, .day, .isLeapMonth], from: date)
        let m = c.month ?? 1, d = c.day ?? 1
        let g = Days.ymd(n)
        let day = Day(y: m > g.m ? g.y - 1 : g.y, m: m, d: d, leap: c.isLeapMonth ?? false)
        dayCache[n] = day
        return day
    }

    /// Every month of lunar year `y`, in order (13 in a leap year).
    static func months(_ y: Int) -> [Month] {
        lock.lock(); defer { lock.unlock() }
        if let hit = yearCache[y] { return hit }
        var s = Days.num(y, 1, 19)
        for i in 0..<40 {
            let l = fromSolarLocked(s + i)
            if l.m == 1 && !l.leap && l.d == 1 { s += i; break }
        }
        var out: [Month] = [], cur = s
        for k in 0..<14 {
            let a = fromSolarLocked(cur)
            if k > 0 && a.m == 1 && !a.leap { break }
            let len = fromSolarLocked(cur + 29).d == 1 ? 29 : 30
            out.append(Month(m: a.m, leap: a.leap, start: cur, len: len))
            cur += len
        }
        yearCache[y] = out
        return out
    }

    static func month(_ y: Int, _ m: Int, leap: Bool) -> Month? {
        months(y).first { $0.m == m && $0.leap == leap }
    }

    /// Day number for a lunar date. Day 30 becomes 29 in short months; a missing leap month falls back to the regular one.
    static func toSolar(_ y: Int, _ m: Int, _ d: Int, leap: Bool) -> Int? {
        guard let mo = month(y, m, leap: leap) ?? month(y, m, leap: false) else { return nil }
        return mo.start + min(d, mo.len) - 1
    }

    private static let monthNames = ["正", "二", "三", "四", "五", "六", "七", "八", "九", "十", "冬", "腊"]
    private static let nums = ["", "一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
    private static let stems = Array("甲乙丙丁戊己庚辛壬癸").map(String.init)
    private static let branches = Array("子丑寅卯辰巳午未申酉戌亥").map(String.init)
    private static let animals = Array("鼠牛虎兔龙蛇马羊猴鸡狗猪").map(String.init)
    private static let animalsEN = ["Rat", "Ox", "Tiger", "Rabbit", "Dragon", "Snake", "Horse", "Goat", "Monkey", "Rooster", "Dog", "Pig"]

    static func monthName(_ m: Int, leap: Bool) -> String { (leap ? "闰" : "") + monthNames[max(0, min(11, m - 1))] + "月" }

    static func dayName(_ d: Int) -> String {
        switch d {
        case ...10: return "初" + nums[max(1, d)]
        case 11...19: return "十" + nums[d - 10]
        case 20: return "二十"
        case 21...29: return "廿" + nums[d - 20]
        default: return "三十"
        }
    }

    private static func mod(_ a: Int, _ n: Int) -> Int { ((a % n) + n) % n }
    static func ganzhi(_ y: Int) -> String { stems[mod(y - 4, 10)] + branches[mod(y - 4, 12)] }
    static func zodiac(_ y: Int) -> String { animals[mod(y - 4, 12)] }
    static func zodiacEN(_ y: Int) -> String { animalsEN[mod(y - 4, 12)] }

    static func text(_ n: Int, withYear: Bool = false) -> String {
        let l = fromSolar(n)
        let s = monthName(l.m, leap: l.leap) + dayName(l.d)
        return withYear ? ganzhi(l.y) + "年 " + s : s
    }
}
