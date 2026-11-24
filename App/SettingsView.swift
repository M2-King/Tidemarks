import SwiftUI
import UIKit
import UserNotifications

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appearance", store: Prefs.defaults) private var appearance = "system"
    @AppStorage("language", store: Prefs.defaults) private var language = "system"
    @AppStorage("defaultRemind", store: Prefs.defaults) private var defaultRemind = "none"
    @AppStorage("defaultTime", store: Prefs.defaults) private var defaultTime = "09:00"
    @State private var notif: UNAuthorizationStatus = .notDetermined
    private let shareMode = Store.shareMode

    private static let remindOptions = ["none", "0", "1", "3", "7", "milestone"]

    private var timeBinding: Binding<Date> {
        Binding(
            get: {
                let t = defaultTime.split(separator: ":").compactMap { Int($0) }
                return Calendar.current.date(from: DateComponents(hour: t.first ?? 9, minute: t.count > 1 ? t[1] : 0)) ?? Date()
            },
            set: { d in
                let c = Calendar.current.dateComponents([.hour, .minute], from: d)
                defaultTime = String(format: "%02d:%02d", c.hour ?? 9, c.minute ?? 0)
            })
    }

    private var notifText: String {
        switch notif {
        case .authorized, .provisional, .ephemeral: return L.sOn
        case .denied: return L.sOff
        default: return L.sNotAsked
        }
    }

    private var version: String {
        let info = Bundle.main.infoDictionary
        return "\(info?["CFBundleShortVersionString"] as? String ?? "1.0") (\(info?["CFBundleVersion"] as? String ?? "1"))"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(L.sAppearance, selection: $appearance) {
                        Text(L.sSystem).tag("system")
                        Text(L.sLight).tag("light")
                        Text(L.sDark).tag("dark")
                    }
                    Picker(L.sLanguage, selection: $language) {
                        Text(L.sSystem).tag("system")
                        Text(verbatim: "中文").tag("zh")
                        Text(verbatim: "English").tag("en")
                    }
                }

                Section {
                    Picker(L.remind, selection: $defaultRemind.animation(Theme.spring)) {
                        ForEach(Self.remindOptions, id: \.self) { Text(L.remindLabel($0)).tag($0) }
                    }
                    if defaultRemind != "none" {
                        DatePicker(L.time, selection: timeBinding, displayedComponents: .hourAndMinute)
                    }
                } header: {
                    Text(L.sReminders)
                } footer: {
                    Text(L.sReminderFooter)
                }

                Section {
                    LabeledContent(L.sStatus, value: notifText)
                    if notif == .denied, let url = URL(string: UIApplication.openSettingsURLString) {
                        Link(L.sOpenSettings, destination: url)
                    }
                } header: {
                    Text(L.sNotifications)
                }

                Section {
                    LabeledContent(L.sWidgetData, value: shareMode == .appGroup ? L.sAvailable : shareMode == .keychain ? L.sAvailableKeychain : L.sUnavailable)
                } header: {
                    Text(L.sWidgets)
                } footer: {
                    Text(shareMode == .appGroup ? L.sWidgetOK : shareMode == .keychain ? L.sWidgetKeychain : L.sWidgetBad)
                }

                Section {
                    LabeledContent(L.sVersion, value: version)
                } header: {
                    Text(L.sAbout)
                }
            }
            .navigationTitle(L.settings)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L.done) { dismiss() }.fontWeight(.semibold)
                }
            }
            .task { notif = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus }
        }
    }
}
