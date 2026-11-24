import Foundation

/// Interface text in Chinese or English, following the device's preferred language.
enum L {
    private static let systemZh: Bool = (Locale.preferredLanguages.first ?? "en").lowercased().hasPrefix("zh")
    static var zh: Bool {
        switch Prefs.language {
        case "zh": return true
        case "en": return false
        default: return systemZh
        }
    }
    private static func t(_ c: String, _ e: String) -> String { zh ? c : e }

    static var appTitle: String { t("汐日", "Tidemark") }
    static var settings: String { t("设置", "Settings") }
    static var sAppearance: String { t("外观", "Appearance") }
    static var sSystem: String { t("跟随系统", "System") }
    static var sLight: String { t("浅色", "Light") }
    static var sDark: String { t("深色", "Dark") }
    static var sLanguage: String { t("语言", "Language") }
    static var sReminders: String { t("新日子的默认提醒", "Default Reminder for New Days") }
    static var sReminderFooter: String { t("每个日子都可以在编辑时单独修改。", "You can still change it for each day when editing.") }
    static var sNotifications: String { t("通知", "Notifications") }
    static var sStatus: String { t("状态", "Status") }
    static var sOn: String { t("已开启", "On") }
    static var sOff: String { t("已关闭", "Off") }
    static var sNotAsked: String { t("尚未请求（设置提醒时会询问）", "Not asked yet (asked when you set a reminder)") }
    static var sOpenSettings: String { t("在系统设置中开启", "Turn On in Settings") }
    static var sWidgets: String { t("小组件", "Widgets") }
    static var sWidgetData: String { t("数据共享", "Data Sharing") }
    static var sAvailable: String { t("正常（App Group）", "Working (App Group)") }
    static var sAvailableKeychain: String { t("正常（钥匙串）", "Working (Keychain)") }
    static var sWidgetKeychain: String { t("此签名没有 App Group，已改用钥匙串共享，小组件可以读取你的日子。", "This signature has no App Group, so days are shared through the keychain. Widgets can read them.") }
    static var sUnavailable: String { t("不可用", "Unavailable") }
    static var sWidgetOK: String { t("小组件可以读取你的日子。", "Widgets can read your days.") }
    static var sWidgetBad: String { t("此签名不支持应用和小组件共享数据，小组件无法读取你的日子。请用带 App Group 的证书签名。", "This signature can’t share data between the app and widgets. Sign with a certificate that has an App Group.") }
    static var sAbout: String { t("关于", "About") }
    static var sVersion: String { t("版本", "Version") }
    static var upcoming: String { t("倒数", "Upcoming") }
    static var since: String { t("正数", "Since") }
    static var newEvent: String { t("新建日子", "New Day") }
    static var editEvent: String { t("编辑日子", "Edit Day") }
    static var cancel: String { t("取消", "Cancel") }
    static var done: String { t("完成", "Done") }
    static var edit: String { t("编辑", "Edit") }
    static var close: String { t("关闭", "Close") }
    static var namePh: String { t("名称，例如：妈妈生日", "Name, e.g. Mum’s birthday") }
    static var calendar: String { t("日历", "Calendar") }
    static var solar: String { t("公历", "Gregorian") }
    static var lunar: String { t("农历", "Lunar") }
    static var dateLbl: String { t("日期", "Date") }
    static var pin: String { t("置顶", "Pin to Top") }
    static var includeStart: String { t("起始日算作第 1 天", "Count start day as day 1") }
    static var remind: String { t("提醒", "Reminder") }
    static var remindNone: String { t("不提醒", "None") }
    static var remindDay: String { t("当天", "On the day") }
    static var remindMilestone: String { t("纪念日与每 100 天", "Anniversaries & every 100 days") }
    static func remindBefore(_ n: Int) -> String {
        zh ? (n == 7 ? "提前 1 周" : "提前 \(n) 天") : (n == 7 ? "1 week before" : "\(n) \(n == 1 ? "day" : "days") before")
    }
    static func remindLabel(_ r: String) -> String {
        switch r {
        case "none": return remindNone
        case "0": return remindDay
        case "milestone": return remindMilestone
        default: return remindBefore(Int(r) ?? 1)
        }
    }
    static var time: String { t("时间", "Time") }
    static var del: String { t("删除日子", "Delete Day") }
    static var delConfirm: String { t("删除后无法恢复。", "This can’t be undone.") }
    static var until: String { t("还有", "Days left") }
    static var sinceLbl: String { t("已经", "Days since") }
    static var today: String { t("就是今天", "Today") }
    static var todayShort: String { t("今天", "Today") }
    static func unit(_ n: Int) -> String { zh ? "天" : (n == 1 ? "day" : "days") }
    static var pinned: String { t("置顶", "Pinned") }
    static var untitled: String { t("未命名", "Untitled") }
    static var emptyTitle: String { t("还没有日子", "No days yet") }
    static var emptyText: String { t("添加一个重要的日子，开始倒数或纪念。", "Add an important day to count down to or count up from.") }
    static var addFirst: String { t("添加日子", "Add a Day") }
    static var widgetEmpty: String { t("打开应用添加日子", "Open the app to add a day") }
    static var widgetName: String { t("汐日", "Tidemark") }
    static var widgetDesc: String { t("显示置顶或最近的日子。长按小组件 → 编辑小组件，可选择要显示的日子。", "Shows your pinned or nearest day. Touch and hold → Edit Widget to choose a day.") }
    static var noDay30: String { t("该月只有 29 天，已调整为廿九", "This month has 29 days, so day 30 became day 29") }

    static func status(_ i: DayInfo) -> String {
        switch i.state { case .future: return until; case .past: return sinceLbl; case .today: return todayShort }
    }
    static func weeks(_ n: Int) -> String { zh ? "约 \(n) 周" : "about \(n) weeks" }
    static func ymd(_ y: Int, _ m: Int, _ d: Int) -> String {
        var a: [String] = []
        if zh {
            if y > 0 { a.append("\(y) 年") }
            if m > 0 { a.append("\(m) 个月") }
            if d > 0 || a.isEmpty { a.append("\(d) 天") }
        } else {
            if y > 0 { a.append("\(y) \(y == 1 ? "year" : "years")") }
            if m > 0 { a.append("\(m) \(m == 1 ? "month" : "months")") }
            if d > 0 || a.isEmpty { a.append("\(d) \(d == 1 ? "day" : "days")") }
        }
        return a.joined(separator: " ")
    }

    private static let wdZH = ["星期日", "星期一", "星期二", "星期三", "星期四", "星期五", "星期六"]
    private static let wdsZH = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
    private static let wdEN = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    private static let wdsEN = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    private static let monEN = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    private static let monlEN = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

    static func weekday(_ n: Int) -> String { (zh ? wdZH : wdEN)[Days.weekday(n)] }
    static func date(_ n: Int) -> String { let a = Days.ymd(n); return zh ? "\(a.y)年\(a.m)月\(a.d)日" : "\(monEN[a.m - 1]) \(a.d), \(a.y)" }
    static func dateShort(_ n: Int) -> String {
        let a = Days.ymd(n), w = Days.weekday(n)
        return zh ? "\(a.m)月\(a.d)日 \(wdsZH[w])" : "\(wdsEN[w]), \(monEN[a.m - 1]) \(a.d)"
    }
    static func todayLine(_ n: Int) -> String {
        let a = Days.ymd(n), w = Days.weekday(n)
        return zh ? "\(a.m)月\(a.d)日 \(wdZH[w])" : "\(wdEN[w]), \(monlEN[a.m - 1]) \(a.d)"
    }
    static func lunarYear(_ y: Int) -> String { zh ? Lunar.ganzhi(y) + "年 · " + Lunar.zodiac(y) + "年" : Lunar.ganzhi(y) + " · Year of the " + Lunar.zodiacEN(y) }

    static func notifyToday(_ t: String) -> String { zh ? "今天是「\(t)」" : "Today is “\(t)”" }
    static func notifyBefore(_ t: String, _ n: Int) -> String { zh ? "距离「\(t)」还有 \(n) 天" : "\(n) \(n == 1 ? "day" : "days") until “\(t)”" }
    static func notifyMilestone(_ t: String, _ n: Int) -> String { zh ? "「\(t)」已经 \(n) 天" : "“\(t)”: \(n) days" }
    static func notifyAnniv(_ t: String, _ k: Int) -> String { zh ? "今天是「\(t)」\(k) 周年" : "“\(t)”: \(k) \(k == 1 ? "year" : "years") today" }
}
