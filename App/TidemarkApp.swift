import SwiftUI
import WidgetKit

@main
struct TidemarkApp: App {
    @StateObject private var model = AppModel()
    @AppStorage("appearance", store: Prefs.defaults) private var appearance = "system"
    @AppStorage("language", store: Prefs.defaults) private var language = "system"

    var body: some Scene {
        WindowGroup {
            RootView()
                .id(language)
                .environmentObject(model)
                .tint(Theme.tint)
                .preferredColorScheme(appearance == "light" ? .light : appearance == "dark" ? .dark : nil)
                .onChange(of: language) { _, _ in model.refreshOutputs() }
        }
    }
}

@MainActor
final class AppModel: ObservableObject {
    struct Section: Identifiable {
        let id: String
        let title: String
        let items: [DayEvent]
    }

    @Published var events: [DayEvent]
    @Published var today: Int = Days.today()

    init() {
        if let saved = Store.load() {
            events = saved
            Store.save(saved)
            WidgetCenter.shared.reloadAllTimelines()
        } else {
            let s = Logic.seed()
            events = s
            Store.save(s)
        }
    }

    var sorted: [DayEvent] { Logic.sorted(events, today: today) }

    var sections: [Section] {
        var up: [DayEvent] = [], past: [DayEvent] = []
        for e in sorted {
            if DayInfo(e, today: today).state == .past { past.append(e) } else { up.append(e) }
        }
        var out: [Section] = []
        if !up.isEmpty { out.append(Section(id: "up", title: L.upcoming, items: up)) }
        if !past.isEmpty { out.append(Section(id: "past", title: L.since, items: past)) }
        return out
    }

    func upsert(_ e: DayEvent) {
        withAnimation(Theme.spring) {
            if e.pinned { for i in events.indices where events[i].id != e.id { events[i].pinned = false } }
            if let i = events.firstIndex(where: { $0.id == e.id }) { events[i] = e } else { events.append(e) }
        }
        persist()
    }

    func delete(_ id: String) {
        withAnimation(Theme.spring) { events.removeAll { $0.id == id } }
        persist()
    }

    func refreshDay() {
        let t = Days.today()
        if t != today { withAnimation(Theme.spring) { today = t } }
    }

    /// Re-render widgets and reminders, e.g. after a language change.
    func refreshOutputs() { persist() }

    private func persist() {
        Store.save(events)
        WidgetCenter.shared.reloadAllTimelines()
        Reminders.reschedule(events)
    }
}
