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
    @State private var sceneTags: [SceneTag] = []
    @State private var inactivityHours: Int = 0
    @State private var showAuthAlert = false
    @State private var pendingNotifications: [UNNotificationRequest] = []
    @State private var showDebugInfo = false

    private var settings: UserSettings {
        settingsArray.first ?? UserSettings()
    }
    
    /// 所有启用了提醒的场景标签
    private var enabledReminderTags: [SceneTag] {
        sceneTags.filter { $0.reminderEnabled && $0.isVisible }
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

            // 已启用的提醒列表（只读显示）
            Section {
                if enabledReminderTags.isEmpty {
                    Text(String(localized: "reminder.no_reminders"))
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                } else {
                    ForEach(enabledReminderTags) { tag in
                        HStack {
                            Image(systemName: tag.icon)
                                .foregroundStyle(Color.brandPrimary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(tag.label)
                                    .font(.subheadline)
                                Text(tag.reminderTimeString)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
                
                NavigationLink {
                    TagManagementView()
                } label: {
                    Label(String(localized: "reminder.manage_in_tags"), systemImage: "tag")
                        .foregroundStyle(.brandPrimary)
                }
            } header: {
                Text(String(localized: "reminder.measurement_reminders"))
            } footer: {
                Text(String(localized: "reminder.manage_footer"))
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
                .onChange(of: inactivityHours) { _, newValue in
                    settings.inactivityReminderHours = newValue
                    if newValue > 0 {
                        notificationManager.scheduleInactivityReminder(hours: newValue)
                    }
                    scheduleAllReminders()
                }
            }
            
            // 调试工具（仅在开发环境显示）
            #if DEBUG
            Section {
                Button(action: {
                    Task {
                        pendingNotifications = await notificationManager.getPendingNotifications()
                        showDebugInfo.toggle()
                    }
                }) {
                    Label("查看待处理的通知", systemImage: "list.bullet")
                }
                
                if !enabledReminderTags.isEmpty {
                    Button(action: {
                        if let firstTag = enabledReminderTags.first {
                            notificationManager.sendTestNotification(label: firstTag.label)
                        }
                    }) {
                        Label("发送测试通知（3秒后）", systemImage: "bell.badge")
                    }
                    
                    Text("点击后保持应用在前台，等待3秒即可看到通知横幅")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                if showDebugInfo {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("待处理通知: \(pendingNotifications.count) 个")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        ForEach(pendingNotifications, id: \.identifier) { notification in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("ID: \(notification.identifier)")
                                    .font(.caption2)
                                if let trigger = notification.trigger as? UNCalendarNotificationTrigger,
                                   let nextDate = trigger.nextTriggerDate() {
                                    Text("触发时间: \(nextDate.formatted())")
                                        .font(.caption2)
                                }
                                Text("标题: \(notification.content.title)")
                                    .font(.caption2)
                            }
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                }
            } header: {
                Text("调试工具")
            } footer: {
                Text("此部分仅在开发版本中显示")
            }
            #endif
        }
        .navigationTitle(String(localized: "reminder.title"))
        .task {
            await notificationManager.checkAuthorizationStatus()
            loadReminders()
        }
        .onChange(of: sceneTags) { _, _ in
            // 标签变化时刷新通知列表
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000) // 等待0.5秒让通知调度完成
                pendingNotifications = await notificationManager.getPendingNotifications()
            }
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
        sceneTags = settings.sceneTags
        inactivityHours = settings.inactivityReminderHours
    }
    
    private func scheduleAllReminders() {
        let enabledTags = settings.sceneTags.filter { $0.reminderEnabled && $0.isVisible }
        let reminders = enabledTags.map { tag in
            ReminderConfig(
                id: tag.id,
                sceneTagId: tag.id,
                hour: tag.reminderHour,
                minute: tag.reminderMinute,
                isEnabled: true
            )
        }
        notificationManager.scheduleReminders(reminders, sceneTags: settings.sceneTags)
    }
}

#Preview {
    NavigationStack {
        ReminderSettingsView()
            .modelContainer(for: [UserSettings.self], inMemory: true)
    }
}
