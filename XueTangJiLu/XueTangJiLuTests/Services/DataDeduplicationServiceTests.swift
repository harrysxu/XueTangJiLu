//
//  DataDeduplicationServiceTests.swift
//  XueTangJiLuTests
//
//  Created by AI Assistant on 2026/2/23.
//

import Testing
import Foundation
import SwiftData
@testable import XueTangJiLu

struct DataDeduplicationServiceTests {
    
    // MARK: - 血糖记录去重测试
    
    @Test("血糖记录去重 - 无重复")
    @MainActor
    func testDeduplicateGlucoseRecordsNoDuplicates() async throws {
        let context = try TestDataFactory.createMockModelContext()
        let service = DataDeduplicationService()
        
        let record1 = TestDataFactory.createGlucoseRecord(value: 5.6, timestamp: TestDataFactory.daysAgo(1))
        let record2 = TestDataFactory.createGlucoseRecord(value: 6.2, timestamp: TestDataFactory.daysAgo(2))
        
        context.insert(record1)
        context.insert(record2)
        
        try service.deduplicateGlucoseRecords(context: context)
        
        let descriptor = FetchDescriptor<GlucoseRecord>()
        let records = try context.fetch(descriptor)
        
        #expect(records.count == 2) // 两条都应保留
    }
    
    @Test("血糖记录去重 - 有重复")
    @MainActor
    func testDeduplicateGlucoseRecordsWithDuplicates() async throws {
        let context = try TestDataFactory.createMockModelContext()
        let service = DataDeduplicationService()
        
        let timestamp = Date.now
        let record1 = TestDataFactory.createGlucoseRecord(value: 5.6, timestamp: timestamp)
        let record2 = TestDataFactory.createGlucoseRecord(value: 5.6, timestamp: timestamp) // 重复
        let record3 = TestDataFactory.createGlucoseRecord(value: 6.0, timestamp: TestDataFactory.daysAgo(1))
        
        context.insert(record1)
        context.insert(record2)
        context.insert(record3)
        
        try service.deduplicateGlucoseRecords(context: context)
        
        let descriptor = FetchDescriptor<GlucoseRecord>()
        let records = try context.fetch(descriptor)
        
        #expect(records.count == 2) // 重复的应该被删除，保留2条
    }
    
    @Test("血糖记录去重 - 冲突解决")
    @MainActor
    func testDeduplicateGlucoseRecordsConflictResolution() async throws {
        let context = try TestDataFactory.createMockModelContext()
        let service = DataDeduplicationService()
        
        let timestamp = Date.now
        let createdEarlier = Date.now.addingTimeInterval(-100)
        let createdLater = Date.now
        
        let record1 = TestDataFactory.createGlucoseRecord(value: 5.6, timestamp: timestamp)
        record1.createdAt = createdEarlier
        
        let record2 = TestDataFactory.createGlucoseRecord(value: 5.6, timestamp: timestamp)
        record2.createdAt = createdLater
        
        context.insert(record1)
        context.insert(record2)
        
        try service.deduplicateGlucoseRecords(context: context)
        
        let descriptor = FetchDescriptor<GlucoseRecord>()
        let records = try context.fetch(descriptor)
        
        #expect(records.count == 1)
        #expect(records.first?.createdAt == createdEarlier) // 保留更早创建的
    }
    
    // MARK: - 用药记录去重测试
    
    @Test("用药记录去重 - 无重复")
    @MainActor
    func testDeduplicateMedicationRecordsNoDuplicates() async throws {
        let context = try TestDataFactory.createMockModelContext()
        let service = DataDeduplicationService()
        
        let record1 = TestDataFactory.createMedicationRecord(name: "诺和锐", dosage: 4.0, timestamp: TestDataFactory.daysAgo(1))
        let record2 = TestDataFactory.createMedicationRecord(name: "来得时", dosage: 8.0, timestamp: TestDataFactory.daysAgo(2))
        
        context.insert(record1)
        context.insert(record2)
        
        try service.deduplicateMedicationRecords(context: context)
        
        let descriptor = FetchDescriptor<MedicationRecord>()
        let records = try context.fetch(descriptor)
        
        #expect(records.count == 2)
    }
    
    @Test("用药记录去重 - 有重复")
    @MainActor
    func testDeduplicateMedicationRecordsWithDuplicates() async throws {
        let context = try TestDataFactory.createMockModelContext()
        let service = DataDeduplicationService()
        
        let timestamp = Date.now
        let record1 = TestDataFactory.createMedicationRecord(name: "诺和锐", dosage: 4.0, timestamp: timestamp)
        let record2 = TestDataFactory.createMedicationRecord(name: "诺和锐", dosage: 4.0, timestamp: timestamp) // 重复
        
        context.insert(record1)
        context.insert(record2)
        
        try service.deduplicateMedicationRecords(context: context)
        
        let descriptor = FetchDescriptor<MedicationRecord>()
        let records = try context.fetch(descriptor)
        
        #expect(records.count == 1)
    }
    
    // MARK: - 饮食记录去重测试
    
    @Test("饮食记录去重 - 无重复")
    @MainActor
    func testDeduplicateMealRecordsNoDuplicates() async throws {
        let context = try TestDataFactory.createMockModelContext()
        let service = DataDeduplicationService()
        
        let record1 = TestDataFactory.createMealRecord(mealDescription: "早餐", timestamp: TestDataFactory.daysAgo(1))
        let record2 = TestDataFactory.createMealRecord(mealDescription: "午餐", timestamp: TestDataFactory.daysAgo(2))
        
        context.insert(record1)
        context.insert(record2)
        
        try service.deduplicateMealRecords(context: context)
        
        let descriptor = FetchDescriptor<MealRecord>()
        let records = try context.fetch(descriptor)
        
        #expect(records.count == 2)
    }
    
    @Test("饮食记录去重 - 有重复")
    @MainActor
    func testDeduplicateMealRecordsWithDuplicates() async throws {
        let context = try TestDataFactory.createMockModelContext()
        let service = DataDeduplicationService()
        
        let timestamp = Date.now
        let record1 = TestDataFactory.createMealRecord(mealDescription: "早餐", timestamp: timestamp)
        let record2 = TestDataFactory.createMealRecord(mealDescription: "早餐", timestamp: timestamp) // 重复
        
        context.insert(record1)
        context.insert(record2)
        
        try service.deduplicateMealRecords(context: context)
        
        let descriptor = FetchDescriptor<MealRecord>()
        let records = try context.fetch(descriptor)
        
        #expect(records.count == 1)
    }
    
    // MARK: - 批量去重测试
    
    @Test("批量去重")
    @MainActor
    func testDeduplicateAll() async throws {
        let context = try TestDataFactory.createMockModelContext()
        let service = DataDeduplicationService()
        
        let timestamp = Date.now
        
        // 添加重复的血糖记录
        context.insert(TestDataFactory.createGlucoseRecord(value: 5.6, timestamp: timestamp))
        context.insert(TestDataFactory.createGlucoseRecord(value: 5.6, timestamp: timestamp))
        
        // 添加重复的用药记录
        context.insert(TestDataFactory.createMedicationRecord(name: "诺和锐", dosage: 4.0, timestamp: timestamp))
        context.insert(TestDataFactory.createMedicationRecord(name: "诺和锐", dosage: 4.0, timestamp: timestamp))
        
        try service.deduplicateAll(context: context)
        
        let glucoseDescriptor = FetchDescriptor<GlucoseRecord>()
        let glucoseRecords = try context.fetch(glucoseDescriptor)
        #expect(glucoseRecords.count == 1)
        
        let medDescriptor = FetchDescriptor<MedicationRecord>()
        let medRecords = try context.fetch(medDescriptor)
        #expect(medRecords.count == 1)
        
        // 应该创建了一个UserSettings
        let settingsDescriptor = FetchDescriptor<UserSettings>()
        let settings = try context.fetch(settingsDescriptor)
        #expect(settings.count == 1)
    }
    
    // MARK: - UserSettings去重测试
    
    @Test("UserSettings去重 - 创建默认实例")
    @MainActor
    func testDeduplicateUserSettingsCreatesDefault() async throws {
        let context = try TestDataFactory.createMockModelContext()
        let service = DataDeduplicationService()
        
        let settings = try service.deduplicateUserSettings(context: context)
        
        let descriptor = FetchDescriptor<UserSettings>()
        let allSettings = try context.fetch(descriptor)
        
        #expect(allSettings.count == 1)
        #expect(settings === allSettings.first)
    }
    
    @Test("UserSettings去重 - 单个实例")
    @MainActor
    func testDeduplicateUserSettingsSingleInstance() async throws {
        let context = try TestDataFactory.createMockModelContext()
        let service = DataDeduplicationService()
        
        let original = UserSettings()
        context.insert(original)
        
        let settings = try service.deduplicateUserSettings(context: context)
        
        let descriptor = FetchDescriptor<UserSettings>()
        let allSettings = try context.fetch(descriptor)
        
        #expect(allSettings.count == 1)
        #expect(settings === original)
    }
    
    @Test("UserSettings去重 - 多个实例合并")
    @MainActor
    func testDeduplicateUserSettingsMultipleInstances() async throws {
        let context = try TestDataFactory.createMockModelContext()
        let service = DataDeduplicationService()
        
        let settings1 = UserSettings()
        settings1.hasCompletedOnboarding = false
        settings1.lastModified = Date.now.addingTimeInterval(-100)
        
        let settings2 = UserSettings()
        settings2.hasCompletedOnboarding = true
        settings2.healthKitSyncEnabled = true
        settings2.lastModified = Date.now
        
        context.insert(settings1)
        context.insert(settings2)
        
        let kept = try service.deduplicateUserSettings(context: context)
        
        let descriptor = FetchDescriptor<UserSettings>()
        let allSettings = try context.fetch(descriptor)
        
        #expect(allSettings.count == 1)
        // 应该合并了两个设置的数据
        #expect(kept.hasCompletedOnboarding == true)
        #expect(kept.healthKitSyncEnabled == true)
    }
}
