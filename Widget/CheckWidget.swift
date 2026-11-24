import SwiftUI
import WidgetKit

/// Diagnostic widget: no intents, no settings. Shows whether the widget can run and see the app's data.
struct CheckEntry: TimelineEntry {
    let date: Date
    let groupOK: Bool
    let keychain: String
    let count: Int
}

struct CheckProvider: TimelineProvider {
    func placeholder(in context: Context) -> CheckEntry { CheckEntry(date: Date(), groupOK: true, keychain: "-", count: 0) }
    func getSnapshot(in context: Context, completion: @escaping (CheckEntry) -> Void) { completion(make()) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<CheckEntry>) -> Void) {
        completion(Timeline(entries: [make()], policy: .after(Date().addingTimeInterval(900))))
    }
    private func make() -> CheckEntry {
        let kc = SharedKeychain.read()
        return CheckEntry(date: Date(), groupOK: Store.sharedContainerAvailable,
                          keychain: kc != nil ? "OK" : "\(SharedKeychain.teamPrefix == nil ? "no team" : "error") \(SharedKeychain.lastStatus)",
                          count: Store.load()?.count ?? 0)
    }
}

struct CheckWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TidemarkCheck", provider: CheckProvider()) { e in
            VStack(alignment: .leading, spacing: 6) {
                Text("Tidemark Check").font(.system(size: 13, weight: .bold))
                Label("Widget running", systemImage: "checkmark.circle.fill").font(.system(size: 12))
                Label(e.groupOK ? "Group: \(Store.groupID)" : "No App Group", systemImage: e.groupOK ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 12))
                Text("Keychain: \(e.keychain)").font(.system(size: 12))
                Text("Days found: \(e.count)").font(.system(size: 12))
                Text(e.date, style: .time).font(.system(size: 11)).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .containerBackground(for: .widget) { Color(.systemBackground) }
        }
        .configurationDisplayName("Tidemark Check")
        .description("Diagnostic: shows whether widgets can run and read your days.")
        .supportedFamilies([.systemSmall])
    }
}
