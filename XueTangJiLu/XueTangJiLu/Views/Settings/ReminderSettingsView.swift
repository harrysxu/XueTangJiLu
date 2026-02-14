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
    @State private var reminders: [ReminderConfig] = ReminderConfig.defaults
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
                    Label("通知权限", systemImage: "bell.badge")
                    Spacer()
                    if notificationManager.isAuthorized {
                        Text("已开启")
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else {
                        Button("开启") {
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
            Section("测量提醒") {
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
            Section("久未记录提醒") {
                Picker("提醒间隔", selection: $inactivityHours) {
                    Text("关闭").tag(0)
                    Text("4 小时").tag(4)
                    Text("6 小时").tag(6)
                    Text("8 小时").tag(8)
                    Text("12 小时").tag(12)
                }
            }

            // 保存
            Section {
                Button(action: saveReminders) {
                    Text("保存提醒设置")
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
        .navigationTitle("提醒设置")
        .task {
            await notificationManager.checkAuthorizationStatus()
            loadReminders()
        }
        .alert("需要通知权限", isPresented: $showAuthAlert) {
            Button("去设置") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("请在系统设置中开启通知权限")
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
