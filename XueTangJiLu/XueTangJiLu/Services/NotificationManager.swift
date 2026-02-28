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
            #if DEBUG
            print("通知权限请求失败: \(error)")
            #endif
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
    func scheduleReminders(_ reminders: [ReminderConfig], sceneTags: [SceneTag] = []) async {
        removeAllReminders()
        
        let enabledReminders = reminders.filter { $0.isEnabled }
        guard !enabledReminders.isEmpty else {
            #if DEBUG
            print("🔔 没有启用的提醒，跳过调度")
            #endif
            return
        }
        
        #if DEBUG
        print("🔔 开始调度提醒，共 \(enabledReminders.count) 个")
        #endif
        
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        
        switch settings.authorizationStatus {
        case .notDetermined:
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                if granted {
                    isAuthorized = true
                } else {
                    return
                }
            } catch {
                return
            }
        case .denied:
            return
        case .authorized, .provisional, .ephemeral:
            break
        @unknown default:
            break
        }
        
        await doScheduleReminders(enabledReminders, sceneTags: sceneTags)
    }
    
    /// 实际执行调度逻辑
    private func doScheduleReminders(_ reminders: [ReminderConfig], sceneTags: [SceneTag]) async {
        let center = UNUserNotificationCenter.current()
        
        for reminder in reminders {
            let content = UNMutableNotificationContent()
            content.title = String(localized: "notification.glucose_reminder_title")
            
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

            do {
                try await center.add(request)
                #if DEBUG
                print("✅ 已调度提醒: \(label) at \(reminder.hour):\(String(format: "%02d", reminder.minute))")
                if let nextDate = trigger.nextTriggerDate() {
                    print("   下次触发: \(nextDate.formatted(date: .abbreviated, time: .shortened))")
                }
                #endif
            } catch {
                #if DEBUG
                print("❌ 设置提醒失败: \(error)")
                #endif
            }
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
    func sendTestNotification(label: String) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        
        #if DEBUG
        print("🔍 通知权限状态: \(settings.authorizationStatus.rawValue)")
        #endif
        
        switch settings.authorizationStatus {
        case .notDetermined:
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                if granted {
                    isAuthorized = true
                } else {
                    return
                }
            } catch {
                return
            }
        case .denied:
            return
        case .authorized, .provisional, .ephemeral:
            break
        @unknown default:
            break
        }
        
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
        
        do {
            try await center.add(request)
            #if DEBUG
            print("✅ 测试通知已调度，3秒后触发")
            #endif
        } catch {
            #if DEBUG
            print("❌ 发送测试通知失败: \(error)")
            #endif
        }
    }
}

// ReminderConfig 定义在 UserSettings.swift 中，以便 Widget 扩展也能访问
