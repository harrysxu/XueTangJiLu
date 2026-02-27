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
    ///   - sceneTags: 场景标签列表（用于获取标签名称）
    func scheduleReminders(_ reminders: [ReminderConfig], sceneTags: [SceneTag] = []) {
        removeAllReminders()
        
        let enabledReminders = reminders.filter { $0.isEnabled }
        guard !enabledReminders.isEmpty else {
            print("🔔 没有启用的提醒，跳过调度")
            return
        }
        
        print("🔔 开始调度提醒，共 \(enabledReminders.count) 个")
        
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { [weak self] settings in
            guard let self else { return }
            
            switch settings.authorizationStatus {
            case .notDetermined:
                print("🔔 通知权限未请求，自动请求授权...")
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if granted {
                        print("✅ 用户已授权通知")
                        self.isAuthorized = true
                        self.doScheduleReminders(enabledReminders, sceneTags: sceneTags)
                    } else {
                        print("❌ 用户拒绝了通知权限: \(error?.localizedDescription ?? "无")")
                    }
                }
                return
            case .denied:
                print("⚠️ 通知权限已被拒绝，请到 设置 > 通知 中手动开启")
                return
            case .authorized, .provisional, .ephemeral:
                break
            @unknown default:
                break
            }
            
            self.doScheduleReminders(enabledReminders, sceneTags: sceneTags)
        }
    }
    
    /// 实际执行调度逻辑
    private func doScheduleReminders(_ reminders: [ReminderConfig], sceneTags: [SceneTag]) {
        for reminder in reminders {
            let content = UNMutableNotificationContent()
            content.title = String(localized: "notification.glucose_reminder_title")
            
            // 从场景标签获取名称
            let label = reminder.label(from: sceneTags)
            content.body = String(localized: "notification.glucose_reminder_labeled", defaultValue: "\(label) - 记得记录血糖")
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
                    print("❌ 设置提醒失败: \(error)")
                } else {
                    print("✅ 已调度提醒: \(label) at \(reminder.hour):\(String(format: "%02d", reminder.minute))")
                    if let nextDate = trigger.nextTriggerDate() {
                        print("   下次触发: \(nextDate)")
                    }
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
    
    // MARK: - 调试功能
    
    /// 获取所有待处理的通知（用于调试）
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await UNUserNotificationCenter.current().pendingNotificationRequests()
    }
    
    /// 发送测试通知（立即触发，用于调试）
    func sendTestNotification(label: String) {
        let center = UNUserNotificationCenter.current()
        
        center.getNotificationSettings { [weak self] settings in
            print("🔍 通知权限状态: \(settings.authorizationStatus.rawValue) (0=未请求, 1=拒绝, 2=已授权, 3=临时)")
            print("   横幅设置: \(settings.alertSetting.rawValue) (0=不支持, 1=禁用, 2=启用)")
            print("   声音设置: \(settings.soundSetting.rawValue)")
            
            switch settings.authorizationStatus {
            case .notDetermined:
                print("🔔 通知权限未请求，自动请求授权...")
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    if granted {
                        self?.isAuthorized = true
                        self?.doSendTestNotification(label: label)
                    } else {
                        print("❌ 用户拒绝了通知权限")
                    }
                }
            case .denied:
                print("❌ 通知权限已被拒绝！请到 设置 > 通知 中手动开启")
            case .authorized, .provisional, .ephemeral:
                self?.doSendTestNotification(label: label)
            @unknown default:
                break
            }
        }
    }
    
    private func doSendTestNotification(label: String) {
        let content = UNMutableNotificationContent()
        content.title = "🧪 " + String(localized: "notification.glucose_reminder_title")
        content.body = String(localized: "notification.glucose_reminder_labeled", defaultValue: "\(label) - 记得记录血糖")
        content.sound = .default
        content.categoryIdentifier = "GLUCOSE_REMINDER"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "test_reminder_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("❌ 发送测试通知失败: \(error)")
            } else {
                print("✅ 测试通知已调度，3秒后触发")
                print("   提示：保持应用在前台即可看到通知横幅")
            }
        }
    }
}

// ReminderConfig 定义在 UserSettings.swift 中，以便 Widget 扩展也能访问
