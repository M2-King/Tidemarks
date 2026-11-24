import Intents

/// Supplies the app's days to the widget's "Edit Widget" picker.
final class IntentHandler: INExtension, PickDayIntentHandling {
    override func handler(for intent: INIntent) -> Any { self }

    func provideDayOptionsCollection(for intent: PickDayIntent, with completion: @escaping (INObjectCollection<WidgetDay>?, Error?) -> Void) {
        let items = Logic.sorted(Store.load() ?? [], today: Days.today()).map { e -> WidgetDay in
            let i = DayInfo(e, today: Days.today())
            let title = e.title.isEmpty ? L.untitled : e.title
            let day = WidgetDay(identifier: e.id, display: title)
            day.subtitleString = L.dateShort(i.n) + " · " + Lunar.text(i.n)
            return day
        }
        completion(INObjectCollection(items: items), nil)
    }

    func handle(intent: PickDayIntent, completion: @escaping (PickDayIntentResponse) -> Void) {
        completion(PickDayIntentResponse(code: .success, userActivity: nil))
    }
}
