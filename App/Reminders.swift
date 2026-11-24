import Foundation
import UserNotifications

enum Reminders {
    static func reschedule(_ events: [DayEvent]) {
        let center = UNUserNotificationCenter.current()
        let items = Array(Logic.notifications(events).prefix(60))
        center.getPendingNotificationRequests { pending in
            center.removePendingNotificationRequests(withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix("cd-") })
            guard !items.isEmpty else { return }
            center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                guard granted else { return }
                for it in items {
                    let content = UNMutableNotificationContent()
                    content.title = L.appTitle
                    content.body = it.body
                    content.sound = .default
                    content.threadIdentifier = "tidemark"
                    let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: it.at)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                    center.add(UNNotificationRequest(identifier: it.id, content: content, trigger: trigger))
                }
            }
        }
    }
}
