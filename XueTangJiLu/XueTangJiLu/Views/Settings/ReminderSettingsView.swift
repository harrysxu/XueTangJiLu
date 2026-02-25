//
//  ReminderSettingsView.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/14.
//

import SwiftUI
import SwiftData

/// 提醒设置页
struct ReminderSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsArray: [UserSettings]
    @State private var notificationManager = NotificationManager()
    @State private var reminders: [ReminderConfig] = ReminderConfig.localizedDefaults()
    @State private var inactivityHours: Int = 0
    @State private var showAuthAlert = false

    private var settings: UserSettings {
        settingsArray.first ?? UserSettings()
    }

    var body: some View {
        Form {
            // 授权状态
            Section {
                HStack {
                    Label(String(localized: "reminder.notification_permission"), systemImage: "bell.badge")
                    Spacer()
                    if notificationManager.isAuthorized {
                        Text(String(localized: "reminder.enabled"))
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else {
                        Button(String(localized: "reminder.enable_button")) {
                            Task {
                                let granted = await notificationManager.requestAuthorization()
                                if !granted {
                                    showAuthAlert = true
                                }
                            }
                        }
                        .font(.caption)
                    }
                }
            }

            // 测量提醒
            Section(String(localized: "reminder.measurement_reminders")) {
                ForEach($reminders) { $reminder in
                    HStack {
                        Toggle(isOn: $reminder.isEnabled) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(reminder.label)
                                    .font(.subheadline)
                                Text(reminder.timeString)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            // 久未记录提醒
            Section(String(localized: "reminder.inactivity_reminder")) {
                Picker(String(localized: "reminder.interval"), selection: $inactivityHours) {
                    Text(String(localized: "reminder.off")).tag(0)
                    Text(String(localized: "reminder.hours_4")).tag(4)
                    Text(String(localized: "reminder.hours_6")).tag(6)
                    Text(String(localized: "reminder.hours_8")).tag(8)
                    Text(String(localized: "reminder.hours_12")).tag(12)
                }
            }

            // 保存
            Section {
                Button(action: saveReminders) {
                    Text(String(localized: "reminder.save"))
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.brandPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.buttonMedium))
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle(String(localized: "reminder.title"))
        .task {
            await notificationManager.checkAuthorizationStatus()
            loadReminders()
        }
        .alert(String(localized: "reminder.permission_alert"), isPresented: $showAuthAlert) {
            Button(String(localized: "reminder.go_to_settings")) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button(String(localized: "reminder.cancel"), role: .cancel) {}
        } message: {
            Text(String(localized: "reminder.permission_message"))
        }
    }

    private func loadReminders() {
        if let data = settings.remindersData,
           let decoded = try? JSONDecoder().decode([ReminderConfig].self, from: data) {
            reminders = decoded
        }
        inactivityHours = settings.inactivityReminderHours
    }

    private func saveReminders() {
        if let data = try? JSONEncoder().encode(reminders) {
            settings.remindersData = data
        }
        settings.inactivityReminderHours = inactivityHours
        notificationManager.scheduleReminders(reminders)
        if inactivityHours > 0 {
            notificationManager.scheduleInactivityReminder(hours: inactivityHours)
        }
        HapticManager.success()
    }
}

#Preview {
    NavigationStack {
        ReminderSettingsView()
            .modelContainer(for: [UserSettings.self], inMemory: true)
    }
}
