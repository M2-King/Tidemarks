import Foundation

enum Logic {
    /// Pinned first, then today, upcoming (soonest first), then past (most recent first).
    static func sorted(_ events: [DayEvent], today: Int) -> [DayEvent] {
        func rank(_ e: DayEvent) -> Int {
            let i = DayInfo(e, today: today)
            switch i.state { case .today: return -1; case .future: return i.diff; case .past: return 10_000_000 - i.diff }
        }
        return events.sorted { a, b in
            if a.pinned != b.pinned { return a.pinned }
            let ra = rank(a), rb = rank(b)
            return ra != rb ? ra < rb : a.created < b.created
        }
    }

    static func breakdown(_ ev: DayEvent, _ i: DayInfo, today: Int) -> String {
        if i.state == .today || i.count < 7 { return "" }
        let w = L.weeks(Int((Double(i.count) / 7).rounded()))
        if i.count < 30 { return w }
        let s = i.state == .past ? Days.between(i.n - (ev.includeStart ? 1 : 0), today) : Days.between(today, i.n)
        return L.ymd(s.y, s.m, s.d) + " · " + w
    }

    /// The same date k years later. Lunar days repeat on their lunar date.
    static func anniversary(_ ev: DayEvent, _ k: Int) -> Int? {
        if ev.cal == "lunar", let l = ev.lunar { return Lunar.toSolar(l.y + k, l.m, l.d, leap: false) }
        let a = Days.ymd(ev.dayNum), y = a.y + k
        return Days.num(y, a.m, min(a.d, Days.daysInMonth(y, a.m)))
    }

    struct Note { let id: String; let at: Date; let body: String }

    /// Reminder notifications due within about 13 months, soonest first.
    static func notifications(_ events: [DayEvent], now: Date = Date()) -> [Note] {
        let today = Days.today(now), horizon = today + 400
        var out: [Note] = []
        for ev in events where ev.remind != "none" {
            let tm = ev.remindTime.split(separator: ":").compactMap { Int($0) }
            let hh = tm.first ?? 9, mm = tm.count > 1 ? tm[1] : 0
            let title = ev.title.isEmpty ? L.untitled : ev.title, target = ev.dayNum
            func push(_ day: Int, _ body: String, _ tag: String) {
                guard day >= today, day <= horizon else { return }
                let at = Days.localDate(day, hour: hh, minute: mm)
                if at > now { out.append(Note(id: "cd-\(ev.id)-\(tag)", at: at, body: body)) }
            }
            if ev.remind == "milestone" {
                push(target, L.notifyToday(title), "day")
                let inc = ev.includeStart ? 1 : 0
                var c = 100
                while target + c - inc <= horizon { push(target + c - inc, L.notifyMilestone(title, c), "m\(c)"); c += 100 }
                for k in 1..<200 {
                    guard let d = anniversary(ev, k), d <= horizon else { break }
                    push(d, L.notifyAnniv(title, k), "a\(k)")
                }
            } else {
                let nb = Int(ev.remind) ?? 0
                push(target - nb, nb == 0 ? L.notifyToday(title) : L.notifyBefore(title, nb), "r\(nb)")
            }
        }
        return out.sorted { $0.at < $1.at }
    }

    /// Starter days for a fresh install.
    static func seed() -> [DayEvent] {
        let today = Days.today(), l = Lunar.fromSolar(today), y = Days.ymd(today).y
        let sf = Lunar.toSolar(l.y + 1, 1, 1, leap: false) ?? today + 60
        return [
            DayEvent(id: "seed-sf", title: L.zh ? "春节" : "Spring Festival", date: Days.iso(sf), cal: "lunar",
                     lunar: LunarSpec(y: l.y + 1, m: 1, d: 1, leap: false), remind: "1", created: 1),
            DayEvent(id: "seed-ny", title: L.zh ? "元旦" : "New Year’s Day", date: "\(y + 1)-01-01", created: 2)
        ]
    }
}
