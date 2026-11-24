import SwiftUI
import WidgetKit

struct DayEntry: TimelineEntry {
    let date: Date
    let today: Int
    let list: [DayEvent]
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> DayEntry {
        DayEntry(date: Date(), today: Days.today(), list: Logic.sorted(Logic.seed(), today: Days.today()))
    }

    func snapshot(for configuration: SelectDayIntent, in context: Context) async -> DayEntry {
        let e = entry(configuration, at: Date())
        return e.list.isEmpty && context.isPreview ? placeholder(in: context) : e
    }

    func timeline(for configuration: SelectDayIntent, in context: Context) async -> Timeline<DayEntry> {
        let now = Date()
        let midnight = Calendar.current.startOfDay(for: now.addingTimeInterval(86_400)).addingTimeInterval(5)
        return Timeline(entries: [entry(configuration, at: now), entry(configuration, at: midnight)], policy: .after(midnight))
    }

    private func entry(_ c: SelectDayIntent, at date: Date) -> DayEntry {
        let today = Days.today(date)
        var list = Logic.sorted(Store.load() ?? [], today: today)
        if let id = c.day?.id, let i = list.firstIndex(where: { $0.id == id }) {
            list.insert(list.remove(at: i), at: 0)
        }
        return DayEntry(date: date, today: today, list: list)
    }
}

// MARK: - Pieces

private func name(_ e: DayEvent) -> String { e.title.isEmpty ? L.untitled : e.title }

struct BigNum: View {
    let i: DayInfo
    let size: CGFloat
    var body: some View {
        if i.state == .today {
            Text(L.todayShort).font(.system(size: size * 0.7, weight: .bold, design: .rounded))
                .lineLimit(1).minimumScaleFactor(0.5)
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(i.count.formatted()).font(.system(size: size, weight: .bold, design: .rounded)).monospacedDigit()
                    .tracking(-size * 0.03).lineLimit(1).minimumScaleFactor(0.4)
                Text(L.unit(i.count)).font(.system(size: max(11, size * 0.28), weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct Feature: View {
    let ev: DayEvent
    let today: Int
    var title: CGFloat = 15
    var num: CGFloat = 50
    var body: some View {
        let i = DayInfo(ev, today: today)
        VStack(alignment: .leading, spacing: 0) {
            Text(name(ev)).font(.system(size: title, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.7)
            Text(i.state == .today ? " " : L.status(i)).font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary).padding(.top, 2)
            Spacer(minLength: 4)
            BigNum(i: i, size: num)
            Text(L.dateShort(i.n)).font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary).lineLimit(1).padding(.top, 4)
            Text(Lunar.text(i.n)).font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

struct ListRow: View {
    let ev: DayEvent
    let today: Int
    var title: CGFloat = 14
    var num: CGFloat = 20
    var body: some View {
        let i = DayInfo(ev, today: today)
        HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 1) {
                Text(name(ev)).font(.system(size: title, weight: .semibold)).lineLimit(1)
                Text(L.dateShort(i.n) + " · " + Lunar.text(i.n)).font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: 4)
            if i.state == .today {
                Text(L.todayShort).font(.system(size: num * 0.8, weight: .bold, design: .rounded))
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    if L.zh { Text(L.status(i)).font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary) }
                    Text(i.count.formatted()).font(.system(size: num, weight: .bold, design: .rounded)).monospacedDigit()
                    Text(L.unit(i.count)).font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct Rows: View {
    let items: [DayEvent]
    let today: Int
    var title: CGFloat = 14
    var num: CGFloat = 20
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { k, e in
                if k > 0 { Spacer(minLength: 4) }
                ListRow(ev: e, today: today, title: title, num: num)
            }
            if items.count < 2 { Spacer(minLength: 0) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct VLine: View {
    var body: some View { Rectangle().fill(Color(.separator)).frame(width: 0.5) }
}

// MARK: - Widget view

struct TidemarkWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: DayEntry

    var body: some View {
        Group {
            if let ev = entry.list.first { content(ev) } else { empty }
        }
        .widgetURL(entry.list.first.flatMap { URL(string: "tidemark://day/\($0.id)") })
    }

    @ViewBuilder private var empty: some View {
        switch family {
        case .accessoryInline, .accessoryCircular, .accessoryRectangular:
            Text(L.appTitle).font(.headline)
        default:
            VStack(spacing: 4) {
                Text(L.emptyTitle).font(.system(size: 15, weight: .semibold))
                Text(Store.shareMode != .none ? L.widgetEmpty : (L.zh ? "打开一次汐日应用，同步日子到小组件" : "Open Tidemark once to share your days with widgets"))
                    .font(.system(size: 12)).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
        }
    }

    @ViewBuilder private func content(_ ev: DayEvent) -> some View {
        let today = entry.today, i = DayInfo(ev, today: today), rest = Array(entry.list.dropFirst())
        switch family {
        case .accessoryInline:
            if i.state == .today { Text(L.notifyToday(name(ev))) }
            else if L.zh { Text("\(name(ev)) \(L.status(i)) \(i.count) 天") }
            else { Text("\(name(ev)) · \(i.count) \(L.unit(i.count)) \(i.state == .future ? "left" : "since")") }

        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    if i.state == .today {
                        Text(L.todayShort).font(.system(size: 15, weight: .bold, design: .rounded))
                    } else {
                        Text(i.count.formatted()).font(.system(size: i.count >= 1000 ? 17 : 22, weight: .bold, design: .rounded))
                            .minimumScaleFactor(0.5).lineLimit(1)
                        Text(name(ev)).font(.system(size: 9, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.6)
                    }
                }
                .padding(4)
            }
            .widgetAccentable()

        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 0) {
                Text(name(ev)).font(.system(size: 14, weight: .semibold)).lineLimit(1).widgetAccentable()
                if i.state == .today {
                    Text(L.today).font(.system(size: 24, weight: .bold, design: .rounded))
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(i.count.formatted()).font(.system(size: 26, weight: .bold, design: .rounded)).minimumScaleFactor(0.5)
                        Text(L.unit(i.count) + (L.zh ? "" : (i.state == .future ? " left" : " since")))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                    }
                }
                Text(L.dateShort(i.n) + " · " + Lunar.text(i.n)).font(.system(size: 11)).opacity(0.7).lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

        case .systemMedium:
            HStack(spacing: 16) {
                Feature(ev: ev, today: today, title: 15, num: 46).frame(width: 130)
                VLine()
                Rows(items: Array(rest.prefix(3)), today: today)
            }

        case .systemLarge:
            VStack(alignment: .leading, spacing: 12) {
                header(today)
                Feature(ev: ev, today: today, title: 20, num: 72)
                Divider()
                Rows(items: Array(rest.prefix(4)), today: today, title: 15, num: 22).frame(maxHeight: 150)
            }

        case .systemExtraLarge:
            VStack(alignment: .leading, spacing: 14) {
                header(today)
                HStack(spacing: 24) {
                    Feature(ev: ev, today: today, title: 22, num: 96).frame(width: 280)
                    VLine()
                    Rows(items: Array(rest.prefix(6)), today: today, title: 15, num: 22)
                }
            }

        default:
            Feature(ev: ev, today: today)
        }
    }

    private func header(_ today: Int) -> some View {
        HStack {
            Text(L.appTitle).font(.system(size: 15, weight: .bold))
            Spacer()
            Text(L.todayLine(today)).font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
        }
    }
}

struct TidemarkWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "TidemarkWidget", intent: SelectDayIntent.self, provider: Provider()) { entry in
            TidemarkWidgetView(entry: entry)
                .containerBackground(for: .widget) { Color(.systemBackground) }
        }
        .configurationDisplayName(Text(L.widgetName))
        .description(Text(L.widgetDesc))
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge,
                            .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

@main
struct TidemarkWidgets: WidgetBundle {
    var body: some Widget {
        TidemarkWidget()
        CheckWidget()
    }
}
