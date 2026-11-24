import SwiftUI

enum EditTarget: Identifiable {
    case new
    case edit(DayEvent)
    var id: String {
        switch self {
        case .new: return "new"
        case .edit(let e): return e.id
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.scenePhase) private var phase
    @State private var selection: String?
    @State private var editing: EditTarget?
    @State private var detail: DayEvent?
    @Namespace private var ns
    private let ticker = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var selectedEvent: DayEvent? { model.events.first { $0.id == selection } }

    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width >= 700
            HStack(spacing: 0) {
                Sidebar(wide: wide, selection: selection, ns: ns, onAdd: { editing = .new }, onOpen: { ev in
                    if wide { withAnimation(Theme.spring) { selection = ev.id } } else { detail = ev }
                })
                .frame(width: wide ? min(max(geo.size.width * 0.36, 320), 400) : geo.size.width)

                if wide {
                    DetailPane(event: selectedEvent, today: model.today,
                               onEdit: { if let e = selectedEvent { editing = .edit(e) } },
                               onAdd: { editing = .new })
                        .padding(.vertical, 16)
                        .padding(.trailing, 16)
                }
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .sheet(item: $editing) { target in
            EditView(target: target) { id in withAnimation(Theme.spring) { selection = id } }
                .environmentObject(model)
        }
        .sheet(item: $detail) { ev in
            DetailSheet(eventID: ev.id) { e in
                detail = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { editing = .edit(e) }
            }
            .environmentObject(model)
            .presentationDetents([.medium, .large])
            .presentationCornerRadius(28)
        }
        .onAppear { if selection == nil { selection = model.sorted.first?.id } }
        .onChange(of: phase) { _, p in if p == .active { model.refreshDay() } }
        .onReceive(ticker) { _ in model.refreshDay() }
        .onChange(of: model.events) { _, evs in
            if let s = selection, evs.contains(where: { $0.id == s }) { return }
            withAnimation(Theme.spring) { selection = model.sorted.first?.id }
        }
        .onOpenURL { url in
            let id = url.lastPathComponent
            guard model.events.contains(where: { $0.id == id }) else { return }
            withAnimation(Theme.spring) { selection = id }
        }
    }
}

// MARK: - Sidebar list

struct Sidebar: View {
    @EnvironmentObject private var model: AppModel
    let wide: Bool
    let selection: String?
    let ns: Namespace.ID
    let onAdd: () -> Void
    let onOpen: (DayEvent) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L.appTitle).font(.system(size: 34, weight: .bold)).tracking(-0.7)
                    Text(L.todayLine(model.today) + " · " + (L.zh ? "农历" : "") + Lunar.text(model.today))
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color(.systemBackground))
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.primary))
                }
                .buttonStyle(PressStyle())
                .accessibilityLabel(L.newEvent)
            }
            .padding(.horizontal, wide ? 28 : 20)
            .padding(.top, 20)
            .padding(.bottom, 4)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(model.sections) { sec in
                        HStack {
                            Theme.label(sec.title)
                            Spacer()
                            Theme.label("\(sec.items.count)")
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 22)
                        .padding(.bottom, 6)
                        ForEach(sec.items) { ev in row(ev) }
                    }
                    if model.events.isEmpty {
                        Text(L.emptyText).font(.subheadline).foregroundStyle(.secondary).padding(12).padding(.top, 16)
                    }
                }
                .padding(.horizontal, wide ? 16 : 8)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func row(_ ev: DayEvent) -> some View {
        let i = DayInfo(ev, today: model.today)
        let sel = wide && selection == ev.id
        let secondary: Color = sel ? Color(.systemBackground).opacity(0.62) : Color.secondary
        return Button { onOpen(ev) } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(ev.title.isEmpty ? L.untitled : ev.title)
                        .font(.system(size: 17, weight: .medium)).tracking(-0.2).lineLimit(1)
                    Text(L.dateShort(i.n) + " · " + Lunar.text(i.n))
                        .font(.footnote).foregroundStyle(secondary).lineLimit(1)
                }
                Spacer(minLength: 8)
                if i.state == .today {
                    Text(L.todayShort).font(.system(size: 15, weight: .semibold))
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(i.count.formatted()).font(Theme.num(24))
                            .contentTransition(.numericText(value: Double(i.count)))
                        Text(L.unit(i.count)).font(.footnote.weight(.medium)).foregroundStyle(secondary)
                    }
                }
            }
            .foregroundStyle(sel ? Color(.systemBackground) : Color.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background {
                if sel {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.primary)
                        .matchedGeometryEffect(id: "selection", in: ns)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(PressStyle())
    }
}
