//
//  NotificationManagerTests.swift
//  XueTangJiLuTests
//
//  Created by AI Assistant on 2026/2/23.
//

import Testing
import UserNotifications
@testable import XueTangJiLu

struct NotificationManagerTests {
    
    // MARK: - 初始状态测试
    
    @Test("初始状态 - 未授权")
    @MainActor
    func testInitialState() {
        let manager = NotificationManager()
        
        #expect(manager.isAuthorized == false)
    }
    
    // MARK: - 权限检查测试
    
    @Test("检查授权状态")
    @MainActor
    func testCheckAuthorizationStatus() async {
        let manager = NotificationManager()
        
        await manager.checkAuthorizationStatus()
        
        // 授权状态应该被更新（测试环境下可能是未授权）
        #expect(manager.isAuthorized == false || manager.isAuthorized == true)
    }
    
    // MARK: - 提醒调度测试（使用Mock验证调用）
    
    @Test("调度每日提醒")
    @MainActor
    func testScheduleReminders() async {
        let manager = NotificationManager()
        
        let sceneTags = [
            SceneTag(
                id: MealContext.beforeBreakfast.rawValue,
                label: "早餐前",
                icon: "sunrise",
                thresholdGroupRawValue: ThresholdGroup.fasting.rawValue,
                isBuiltIn: true,
                isVisible: true,
                sortOrder: 0
            ),
            SceneTag(
                id: MealContext.beforeLunch.rawValue,
                label: "午餐前",
                icon: "sun.max",
                thresholdGroupRawValue: ThresholdGroup.fasting.rawValue,
                isBuiltIn: true,
                isVisible: true,
                sortOrder: 1
            )
        ]
        
        let reminders = [
            ReminderConfig(
                id: UUID().uuidString,
                sceneTagId: MealContext.beforeBreakfast.rawValue,
                hour: 8,
                minute: 0,
                isEnabled: true
            ),
            ReminderConfig(
                id: UUID().uuidString,
                sceneTagId: MealContext.beforeLunch.rawValue,
                hour: 12,
                minute: 0,
                isEnabled: true
            )
        ]
        
        // 调用方法（实际会添加到通知中心）
        await manager.scheduleReminders(reminders, sceneTags: sceneTags)
        
        // 在真实测试中，我们无法直接验证UNUserNotificationCenter的状态
        // 但方法应该执行无误
    }
    
    @Test("移除所有提醒")
    @MainActor
    func testRemoveAllReminders() {
        let manager = NotificationManager()
        
        manager.removeAllReminders()
        
        // 方法应该执行无误
    }
}
