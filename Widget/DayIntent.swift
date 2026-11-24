import AppIntents
import Foundation

struct DayEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Day"
    static let defaultQuery = DayQuery()

    let id: String
    let title: String

    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(title)") }
}

struct DayQuery: EntityQuery {
    func entities(for identifiers: [DayEntity.ID]) async throws -> [DayEntity] {
        all().filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [DayEntity] { all() }

    func defaultResult() async -> DayEntity? { nil }

    private func all() -> [DayEntity] {
        Logic.sorted(Store.load() ?? [], today: Days.today()).map {
            DayEntity(id: $0.id, title: $0.title.isEmpty ? L.untitled : $0.title)
        }
    }
}

struct SelectDayIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Choose a Day"
    static let description = IntentDescription("选择应用里的日子，或直接填写名称和日期。Pick a day from the app, or type a name and date.")

    @Parameter(title: "从应用选择 / Day from the app")
    var day: DayEntity?

    @Parameter(title: "名称 / Name")
    var name: String?

    @Parameter(title: "日期 / Date")
    var date: Date?

    @Parameter(title: "起始日算第 1 天 / Count start day", default: false)
    var includeStart: Bool

    init() {}
}
