import SwiftUI

/// Wide screens: the selected day as a poster in the right pane.
struct DetailPane: View {
    let event: DayEvent?
    let today: Int
    let onEdit: () -> Void
    let onAdd: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous).fill(Theme.card)
            if let ev = event {
                Poster(ev: ev, today: today, onEdit: onEdit)
            } else {
                EmptyState(onAdd: onAdd)
            }
        }
    }
}

struct Poster: View {
    let ev: DayEvent
    let today: Int
    let onEdit: () -> Void

    var body: some View {
        let i = DayInfo(ev, today: today)
        GeometryReader { geo in
            let inner = geo.size.width - 72
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 10) {
                        if ev.pinned {
                            Text(L.pinned)
                                .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                                .padding(.horizontal, 10).padding(.vertical, 3)
                                .overlay(Capsule().stroke(Color.secondary.opacity(0.35), lineWidth: 1))
                        }
                        Text(ev.title.isEmpty ? L.untitled : ev.title)
                            .font(.system(size: 30, weight: .bold)).tracking(-0.6).lineLimit(2)
                    }
                    Spacer()
                    Button(action: onEdit) {
                        Text(L.edit).font(.system(size: 15, weight: .semibold))
                            .padding(.horizontal, 18).frame(height: 36)
                            .background(Capsule().fill(Color(.tertiarySystemFill)))
                    }
                    .buttonStyle(PressStyle())
                    .foregroundStyle(.primary)
                }

                Spacer(minLength: 24)

                Theme.label(i.state == .today ? " " : L.status(i)).padding(.bottom, 14)
                bigNumber(i, width: inner)
                Text(Logic.breakdown(ev, i, today: today))
                    .font(.subheadline).foregroundStyle(.secondary).padding(.top, 20)

                Spacer(minLength: 24)

                footer(i, wide: inner >= 520)
            }
            .padding(.horizontal, 36)
            .padding(.top, 30)
            .padding(.bottom, 28)
        }
    }

    @ViewBuilder private func bigNumber(_ i: DayInfo, width: CGFloat) -> some View {
        if i.state == .today {
            Text(L.today).font(.system(size: min(120, max(64, width / 4)), weight: .semibold)).tracking(-1)
        } else {
            let s = i.count.formatted()
            let digits = s.filter(\.isNumber).count, seps = s.count - digits
            let size = min(220, max(88, (width - 90) / (CGFloat(digits) * 0.6 + CGFloat(seps) * 0.28)))
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(s)
                    .font(Theme.num(size, .medium)).tracking(-size * 0.05)
                    .contentTransition(.numericText(value: Double(i.count)))
                    .lineLimit(1).minimumScaleFactor(0.5)
                    .padding(.leading, -size * 0.05)
                Text(L.unit(i.count)).font(.system(size: 24, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder private func footer(_ i: DayInfo, wide: Bool) -> some View {
        let l = Lunar.fromSolar(i.n)
        let on = ev.remind != "none"
        let items: [(String, String, String)] = [
            (L.solar, L.date(i.n), L.weekday(i.n)),
            (L.lunar, Lunar.text(i.n), L.lunarYear(l.y)),
            (L.remind, L.remindLabel(ev.remind), on ? ev.remindTime : "")
        ]
        if wide {
            VStack(spacing: 0) {
                Divider().padding(.bottom, 20)
                HStack(alignment: .top, spacing: 20) {
                    ForEach(items, id: \.0) { k, v, sub in
                        VStack(alignment: .leading, spacing: 3) {
                            Theme.label(k)
                            Text(v).font(.system(size: 17, weight: .semibold)).tracking(-0.2)
                            Text(sub.isEmpty ? " " : sub).font(.footnote).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        } else {
            VStack(spacing: 0) {
                ForEach(items, id: \.0) { k, v, sub in
                    Divider()
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(k).foregroundStyle(.secondary)
                        Spacer()
                        Text(v).fontWeight(.semibold)
                        if !sub.isEmpty { Text(sub).font(.footnote).foregroundStyle(.secondary) }
                    }
                    .padding(.vertical, 13)
                }
            }
        }
    }
}

struct EmptyState: View {
    let onAdd: () -> Void
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar")
                .font(.system(size: 28, weight: .regular)).foregroundStyle(.secondary)
                .frame(width: 64, height: 64)
                .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color(.quaternarySystemFill)))
                .padding(.bottom, 8)
            Text(L.emptyTitle).font(.title2.weight(.semibold))
            Text(L.emptyText).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center).frame(maxWidth: 280)
            Button(action: onAdd) {
                Text(L.addFirst).font(.headline).foregroundStyle(Color(.systemBackground))
                    .padding(.horizontal, 28).frame(height: 50)
                    .background(Capsule().fill(Color.primary))
            }
            .buttonStyle(PressStyle())
            .padding(.top, 14)
        }
        .padding(24)
    }
}

/// Narrow screens: details in a sheet.
struct DetailSheet: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let eventID: String
    let onEdit: (DayEvent) -> Void
    @State private var shown = 0

    var body: some View {
        NavigationStack {
            Group {
                if let ev = model.events.first(where: { $0.id == eventID }) {
                    content(ev)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) { Button(L.close) { dismiss() } }
                            ToolbarItem(placement: .primaryAction) { Button(L.edit) { onEdit(ev) }.fontWeight(.semibold) }
                        }
                } else {
                    Color.clear.onAppear { dismiss() }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func content(_ ev: DayEvent) -> some View {
        let i = DayInfo(ev, today: model.today), l = Lunar.fromSolar(i.n)
        return ScrollView {
            VStack(spacing: 4) {
                Text(ev.title.isEmpty ? L.untitled : ev.title).font(.title2.weight(.semibold)).multilineTextAlignment(.center)
                Text(i.state == .today ? " " : L.status(i)).font(.subheadline).foregroundStyle(.secondary)
                if i.state == .today {
                    Text(L.today).font(.system(size: 64, weight: .semibold)).padding(.vertical, 12)
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(shown.formatted()).font(Theme.num(104, .medium)).tracking(-4)
                            .contentTransition(.numericText(value: Double(shown)))
                        Text(L.unit(i.count)).font(.system(size: 22, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                Text(Logic.breakdown(ev, i, today: model.today)).font(.subheadline).foregroundStyle(.secondary)
                VStack(spacing: 0) {
                    kv(L.solar, L.date(i.n) + " " + L.weekday(i.n))
                    Divider().padding(.leading, 16)
                    kv(L.lunar, Lunar.text(i.n, withYear: true) + " · " + (L.zh ? Lunar.zodiac(l.y) + "年" : Lunar.zodiacEN(l.y)))
                    Divider().padding(.leading, 16)
                    kv(L.remind, ev.remind == "none" ? L.remindNone : L.remindLabel(ev.remind) + " " + ev.remindTime)
                }
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.field))
                .padding(.top, 24)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .onAppear { withAnimation(.easeOut(duration: 0.9)) { shown = i.count } }
    }

    private func kv(_ k: String, _ v: String) -> some View {
        HStack { Text(k).foregroundStyle(.secondary); Spacer(); Text(v).multilineTextAlignment(.trailing) }
            .padding(.horizontal, 16).frame(minHeight: 48)
    }
}
