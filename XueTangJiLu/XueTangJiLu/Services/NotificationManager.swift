//
//  NotificationManager.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/14.
//

import Foundation
import UserNotifications
import Observation

/// 提醒通知管理器
@Observable
final class NotificationManager {

    /// 通知授权状态
    private(set) var isAuthorized = false

    /// 请求通知权限
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            return granted
        } catch {
            print("通知权限请求失败: \(error)")
            return false
        }
    }

    /// 检查当前授权状态
    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - 测量提醒

    /// 设置每日测量提醒
    /// - Parameters:
    ///   - reminders: 提醒配置列表
    func scheduleReminders(_ reminders: [ReminderConfig]) {
        // 先移除旧的提醒
        removeAllReminders()

        for reminder in reminders where reminder.isEnabled {
            let content = UNMutableNotificationContent()
            content.title = String(localized: "notification.glucose_reminder_title")
            content.body = reminder.label.isEmpty ? 
                String(localized: "notification.glucose_reminder_body") : 
                String(localized: "notification.glucose_reminder_labeled", defaultValue: "\(reminder.label) - 记得记录血糖")
            content.sound = .default
            content.categoryIdentifier = "GLUCOSE_REMINDER"

            var dateComponents = DateComponents()
            dateComponents.hour = reminder.hour
            dateComponents.minute = reminder.minute

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: true
            )

            let request = UNNotificationRequest(
                identifier: "reminder_\(reminder.id)",
                content: content,
                trigger: trigger
            )

            UNUserNotificationCenter.current().add(request) { error in
                if let error {
                    print("设置提醒失败: \(error)")
                }
            }
        }
    }

    /// 设置久未记录提醒
    /// - Parameter hours: 未记录超过多少小时后提醒
    func scheduleInactivityReminder(hours: Int) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification.inactivity_title")
        content.body = String(localized: "notification.inactivity_body", defaultValue: "您已经超过 \(hours) 小时没有记录血糖了")
        content.sound = .default
        content.categoryIdentifier = "INACTIVITY_REMINDER"

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(hours * 3600),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "inactivity_reminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("设置久未记录提醒失败: \(error)")
            }
        }
    }

    /// 重置久未记录提醒（在每次记录后调用）
    func resetInactivityReminder(hours: Int) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["inactivity_reminder"]
        )
        if hours > 0 {
            scheduleInactivityReminder(hours: hours)
        }
    }

    /// 移除所有提醒
    func removeAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

// ReminderConfig 定义在 UserSettings.swift 中，以便 Widget 扩展也能访问
