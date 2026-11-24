import SwiftUI

struct EditView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss

    let isNew: Bool
    let onSaved: (String) -> Void

    @State private var draft: DayEvent
    @State private var solarDate: Date
    @State private var ly: Int
    @State private var lm: Int
    @State private var lleap: Bool
    @State private var ld: Int
    @State private var time: Date
    @State private var clamped = false
    @State private var askDelete = false
    @FocusState private var nameFocused: Bool

    private static let remindOptions = ["none", "0", "1", "3", "7", "milestone"]
    private static let range = Days.localDate(Days.num(1901, 2, 19))...Days.localDate(Days.num(2099, 12, 31))

    init(target: EditTarget, onSaved: @escaping (String) -> Void) {
        let ev: DayEvent
        switch target {
        case .new: ev = DayEvent(); isNew = true
        case .edit(let e): ev = e; isNew = false
        }
        self.onSaved = onSaved
        let n = ev.dayNum
        let l = ev.lunar.map { Lunar.Day(y: $0.y, m: $0.m, d: $0.d, leap: $0.leap) } ?? Lunar.fromSolar(n)
        _draft = State(initialValue: ev)
        _solarDate = State(initialValue: Days.localDate(n))
        _ly = State(initialValue: l.y)
        _lm = State(initialValue: l.m)
        _lleap = State(initialValue: l.leap)
        _ld = State(initialValue: l.d)
        let t = ev.remindTime.split(separator: ":").compactMap { Int($0) }
        _time = State(initialValue: Calendar.current.date(from: DateComponents(hour: t.first ?? 9, minute: t.count > 1 ? t[1] : 0)) ?? Date())
    }

    private var currentDay: Int {
        if draft.cal == "lunar" { return Lunar.toSolar(ly, lm, ld, leap: lleap) ?? Days.fromLocalDate(solarDate) }
        return Days.fromLocalDate(solarDate)
    }

    private var hint: String {
        if clamped && draft.cal == "lunar" { return L.noDay30 }
        let n = currentDay
        if draft.cal == "lunar" { return (L.zh ? "对应公历 " : "Gregorian: ") + L.date(n) + " " + L.weekday(n) }
        return (L.zh ? "农历 " : "Lunar: ") + Lunar.text(n, withYear: true)
    }

    private var monthKey: Binding<String> {
        Binding(
            get: { "\(lm)\(lleap ? "L" : "")" },
            set: { v in
                lleap = v.hasSuffix("L")
                lm = Int(v.replacingOccurrences(of: "L", with: "")) ?? 1
                clampLunar()
            })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(L.namePh, text: $draft.title)
                        .font(.system(size: 17, weight: .medium))
                        .focused($nameFocused)
                }

                Section {
                    Picker(L.calendar, selection: $draft.cal.animation(Theme.spring)) {
                        Text(L.solar).tag("solar")
                        Text(L.lunar).tag("lunar")
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())

                    if draft.cal == "solar" {
                        DatePicker(L.dateLbl, selection: $solarDate, in: Self.range, displayedComponents: .date)
                    } else {
                        LabeledContent(L.dateLbl) {
                            HStack(spacing: 2) {
                                Picker("", selection: $ly) {
                                    ForEach(1901...2099, id: \.self) { y in
                                        Text(verbatim: L.zh ? "\(y) \(Lunar.ganzhi(y))" : String(y)).tag(y)
                                    }
                                }
                                Picker("", selection: monthKey) {
                                    ForEach(Lunar.months(ly), id: \.self) { mo in
                                        Text(Lunar.monthName(mo.m, leap: mo.leap)).tag("\(mo.m)\(mo.leap ? "L" : "")")
                                    }
                                }
                                Picker("", selection: $ld) {
                                    ForEach(1...(Lunar.month(ly, lm, leap: lleap)?.len ?? 30), id: \.self) { d in
                                        Text(Lunar.dayName(d)).tag(d)
                                    }
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                        }
                    }
                } footer: {
                    Text(hint).contentTransition(.opacity)
                }

                Section {
                    Toggle(L.pin, isOn: $draft.pinned)
                    Toggle(L.includeStart, isOn: $draft.includeStart)
                }

                Section {
                    Picker(L.remind, selection: $draft.remind.animation(Theme.spring)) {
                        ForEach(Self.remindOptions, id: \.self) { Text(L.remindLabel($0)).tag($0) }
                    }
                    if draft.remind != "none" {
                        DatePicker(L.time, selection: $time, displayedComponents: .hourAndMinute)
                    }
                }

                if !isNew {
                    Section {
                        Button(role: .destructive) { askDelete = true } label: {
                            Text(L.del).frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .navigationTitle(isNew ? L.newEvent : L.editEvent)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(L.cancel) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L.done) { save() }
                        .fontWeight(.semibold)
                        .disabled(draft.title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .confirmationDialog(L.del, isPresented: $askDelete, titleVisibility: .visible) {
                Button(L.del, role: .destructive) {
                    model.delete(draft.id)
                    dismiss()
                }
            } message: {
                Text(L.delConfirm)
            }
            .onChange(of: draft.cal) { _, cal in
                if cal == "lunar" {
                    let l = Lunar.fromSolar(Days.fromLocalDate(solarDate))
                    ly = l.y; lm = l.m; lleap = l.leap; ld = l.d; clamped = false
                } else if let n = Lunar.toSolar(ly, lm, ld, leap: lleap) {
                    solarDate = Days.localDate(n)
                }
            }
            .onChange(of: ly) { _, _ in clampLunar() }
            .onAppear { if isNew { DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { nameFocused = true } } }
        }
    }

    private func clampLunar() {
        if Lunar.month(ly, lm, leap: lleap) == nil { lleap = false }
        let len = Lunar.month(ly, lm, leap: lleap)?.len ?? 30
        clamped = ld > len
        if clamped { ld = len }
    }

    private func save() {
        draft.title = draft.title.trimmingCharacters(in: .whitespaces)
        draft.date = Days.iso(currentDay)
        draft.lunar = draft.cal == "lunar" ? LunarSpec(y: ly, m: lm, d: ld, leap: lleap) : nil
        let c = Calendar.current.dateComponents([.hour, .minute], from: time)
        draft.remindTime = String(format: "%02d:%02d", c.hour ?? 9, c.minute ?? 0)
        model.upsert(draft)
        onSaved(draft.id)
        dismiss()
    }
}
