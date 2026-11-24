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
    static let description = IntentDescription("Choose which day this widget shows. Leave empty to show your pinned or nearest day.")

    @Parameter(title: "Day")
    var day: DayEntity?

    init() {}
}
