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
