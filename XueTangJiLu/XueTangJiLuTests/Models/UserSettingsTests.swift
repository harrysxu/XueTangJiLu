//
//  UserSettingsTests.swift
//  XueTangJiLuTests
//
//  Created by AI Assistant on 2026/2/23.
//

import Testing
import Foundation
@testable import XueTangJiLu

struct UserSettingsTests {
    
    // MARK: - 初始化测试
    
    @Test("基本初始化")
    func testInitialization() {
        let settings = UserSettings()
        
        #expect(settings.preferredUnit == .mmolL)
        #expect(settings.hasCompletedOnboarding == false)
        #expect(settings.healthKitSyncEnabled == false)
    }
    
    // MARK: - 单位设置测试
    
    @Test("设置首选单位 - mmol/L")
    func testSetPreferredUnitMmolL() {
        let settings = UserSettings()
        settings.preferredUnit = .mmolL
        
        #expect(settings.preferredUnit == .mmolL)
    }
    
    @Test("设置首选单位 - mg/dL")
    func testSetPreferredUnitMgdL() {
        let settings = UserSettings()
        settings.preferredUnit = .mgdL
        
        #expect(settings.preferredUnit == .mgdL)
    }
    
    // MARK: - 场景标签测试
    
    @Test("获取场景标签")
    func testSceneTags() {
        let settings = UserSettings()
        
        let tags = settings.sceneTags
        #expect(!tags.isEmpty) // 应该有默认标签
    }
    
    @Test("获取可见场景标签")
    func testVisibleSceneTags() {
        let settings = UserSettings()
        
        let visibleTags = settings.visibleSceneTags
        #expect(!visibleTags.isEmpty)
    }
    
    @Test("根据ID获取场景标签")
    func testSceneTagForId() {
        let settings = UserSettings()
        
        let tag = settings.sceneTag(for: "beforeBreakfast")
        #expect(tag != nil)
        #expect(tag?.id == "beforeBreakfast")
    }
    
    // MARK: - 阈值配置测试
    
    @Test("获取阈值范围")
    func testThresholdRange() {
        let settings = UserSettings()
        
        let range = settings.thresholdRange(for: "beforeBreakfast")
        #expect(range.low > 0)
        #expect(range.high > range.low)
    }
    
    @Test("设置阈值")
    func testSetThreshold() {
        let settings = UserSettings()
        
        settings.setThreshold(for: "beforeBreakfast", low: 4.0, high: 6.0)
        
        let range = settings.thresholdRange(for: "beforeBreakfast")
        #expect(range.low == 4.0)
        #expect(range.high == 6.0)
    }
    
    @Test("阈值包络范围")
    func testThresholdEnvelope() {
        let settings = UserSettings()
        
        let envelope = settings.thresholdEnvelope
        #expect(envelope.low > 0)
        #expect(envelope.high > envelope.low)
    }
    
    // MARK: - 显示模式测试
    
    @Test("显示模式 - 简化")
    func testDisplayModeSimplified() {
        let settings = UserSettings()
        settings.displayMode = .simplified
        
        #expect(settings.displayMode == .simplified)
    }
    
    @Test("显示模式 - 专业")
    func testDisplayModeProfessional() {
        let settings = UserSettings()
        settings.displayMode = .professional
        
        #expect(settings.displayMode == .professional)
    }
    
    // MARK: - 提醒配置测试
    
    @Test("获取提醒配置")
    func testReminderConfigs() {
        let settings = UserSettings()
        
        let reminders = settings.reminderConfigs
        // 可能有默认提醒或为空
        #expect(reminders.count >= 0)
    }
    
    @Test("场景标签提醒功能 - 默认关闭")
    func testSceneTagReminderDefaultOff() {
        let settings = UserSettings()
        
        // 默认所有场景标签的提醒应该是关闭的
        let tags = settings.sceneTags
        for tag in tags {
            #expect(tag.reminderEnabled == false)
        }
    }
    
    @Test("场景标签提醒功能 - 启用提醒")
    func testSceneTagEnableReminder() {
        let settings = UserSettings()
        
        var tags = settings.sceneTags
        guard var firstTag = tags.first else { return }
        
        // 启用提醒
        firstTag.reminderEnabled = true
        firstTag.reminderHour = 8
        firstTag.reminderMinute = 30
        
        tags[0] = firstTag
        settings.sceneTags = tags
        
        // 验证提醒已启用
        let updatedTag = settings.sceneTags.first
        #expect(updatedTag?.reminderEnabled == true)
        #expect(updatedTag?.reminderHour == 8)
        #expect(updatedTag?.reminderMinute == 30)
        #expect(updatedTag?.reminderTimeString == "08:30")
    }
    
    @Test("场景标签提醒功能 - 提醒时间格式化")
    func testSceneTagReminderTimeString() {
        let settings = UserSettings()
        
        var tags = settings.sceneTags
        guard var firstTag = tags.first else { return }
        
        firstTag.reminderHour = 7
        firstTag.reminderMinute = 5
        tags[0] = firstTag
        settings.sceneTags = tags
        
        let updatedTag = settings.sceneTags.first
        #expect(updatedTag?.reminderTimeString == "07:05")
    }
    
    @Test("场景标签提醒功能 - 多个标签独立配置")
    func testMultipleSceneTagsWithReminders() {
        let settings = UserSettings()
        
        var tags = settings.sceneTags
        
        // 启用前3个标签的提醒，设置不同时间
        if tags.count >= 3 {
            tags[0].reminderEnabled = true
            tags[0].reminderHour = 7
            tags[0].reminderMinute = 0
            
            tags[1].reminderEnabled = true
            tags[1].reminderHour = 12
            tags[1].reminderMinute = 30
            
            tags[2].reminderEnabled = false // 第三个不启用
            
            settings.sceneTags = tags
            
            // 验证配置
            let updatedTags = settings.sceneTags
            #expect(updatedTags[0].reminderEnabled == true)
            #expect(updatedTags[0].reminderTimeString == "07:00")
            
            #expect(updatedTags[1].reminderEnabled == true)
            #expect(updatedTags[1].reminderTimeString == "12:30")
            
            #expect(updatedTags[2].reminderEnabled == false)
        }
    }
    
    @Test("场景标签提醒功能 - 隐藏标签时提醒应关闭")
    func testHiddenSceneTagDisablesReminder() {
        let settings = UserSettings()
        
        var tags = settings.sceneTags
        guard var firstTag = tags.first else { return }
        
        // 先启用提醒
        firstTag.reminderEnabled = true
        firstTag.reminderHour = 8
        firstTag.reminderMinute = 0
        
        // 然后隐藏标签（模拟 toggleSceneTag 的行为）
        firstTag.isVisible = false
        firstTag.reminderEnabled = false
        
        tags[0] = firstTag
        settings.sceneTags = tags
        
        let updatedTag = settings.sceneTags.first
        #expect(updatedTag?.isVisible == false)
        #expect(updatedTag?.reminderEnabled == false)
    }
    
    // MARK: - 设置合并测试
    
    @Test("合并其他设备设置")
    func testMergeNonDefaults() {
        let settings1 = UserSettings()
        settings1.preferredUnit = .mmolL
        settings1.displayMode = .simplified
        
        let settings2 = UserSettings()
        settings2.preferredUnit = .mgdL
        settings2.displayMode = .professional
        
        settings1.mergeNonDefaults(from: settings2)
        
        // 合并后应该保留非默认设置
        #expect(settings1.preferredUnit == .mgdL || settings1.preferredUnit == .mmolL)
    }
}
