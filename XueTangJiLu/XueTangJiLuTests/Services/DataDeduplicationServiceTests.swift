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
    func testDeduplicateGlucoseRecordsNoDuplicates() async throws {
        let context = try TestDataFactory.createMockModelContext()
        let service = DataDeduplicationService()
        
        let record1 = TestDataFactory.createGlucoseRecord(value: 5.6, timestamp: TestDataFactory.daysAgo(1))
        let record2 = TestDataFactory.createGlucoseRecord(value: 6.2, timestamp: TestDataFactory.daysAgo(2))
        
        context.insert(record1)
        context.insert(record2)
        
        try await service.deduplicateGlucoseRecords(context: context)
        
        let descriptor = FetchDescriptor<GlucoseRecord>()
        let records = try context.fetch(descriptor)
        
        #expect(records.count == 2) // 两条都应保留
    }
    
    @Test("血糖记录去重 - 有重复")
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
        
        try await service.deduplicateGlucoseRecords(context: context)
        
        let descriptor = FetchDescriptor<GlucoseRecord>()
        let records = try context.fetch(descriptor)
        
        #expect(records.count == 2) // 重复的应该被删除，保留2条
    }
    
    @Test("血糖记录去重 - 冲突解决")
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
        
        try await service.deduplicateGlucoseRecords(context: context)
        
        let descriptor = FetchDescriptor<GlucoseRecord>()
        let records = try context.fetch(descriptor)
        
        #expect(records.count == 1)
        #expect(records.first?.createdAt == createdEarlier) // 保留更早创建的
    }
    
    // MARK: - 用药记录去重测试
    
    @Test("用药记录去重 - 无重复")
    func testDeduplicateMedicationRecordsNoDuplicates() async throws {
        let context = try TestDataFactory.createMockModelContext()
        let service = DataDeduplicationService()
        
        let record1 = TestDataFactory.createMedicationRecord(name: "诺和锐", dosage: 4.0, timestamp: TestDataFactory.daysAgo(1))
        let record2 = TestDataFactory.createMedicationRecord(name: "来得时", dosage: 8.0, timestamp: TestDataFactory.daysAgo(2))
        
        context.insert(record1)
        context.insert(record2)
        
        try await service.deduplicateMedicationRecords(context: context)
        
        let descriptor = FetchDescriptor<MedicationRecord>()
        let records = try context.fetch(descriptor)
        
        #expect(records.count == 2)
    }
    
    @Test("用药记录去重 - 有重复")
    func testDeduplicateMedicationRecordsWithDuplicates() async throws {
        let context = try TestDataFactory.createMockModelContext()
        let service = DataDeduplicationService()
        
        let timestamp = Date.now
        let record1 = TestDataFactory.createMedicationRecord(name: "诺和锐", dosage: 4.0, timestamp: timestamp)
        let record2 = TestDataFactory.createMedicationRecord(name: "诺和锐", dosage: 4.0, timestamp: timestamp) // 重复
        
        context.insert(record1)
        context.insert(record2)
        
        try await service.deduplicateMedicationRecords(context: context)
        
        let descriptor = FetchDescriptor<MedicationRecord>()
        let records = try context.fetch(descriptor)
        
        #expect(records.count == 1)
    }
    
    // MARK: - 饮食记录去重测试
    
    @Test("饮食记录去重 - 无重复")
    func testDeduplicateMealRecordsNoDuplicates() async throws {
        let context = try TestDataFactory.createMockModelContext()
        let service = DataDeduplicationService()
        
        let record1 = TestDataFactory.createMealRecord(mealDescription: "早餐", timestamp: TestDataFactory.daysAgo(1))
        let record2 = TestDataFactory.createMealRecord(mealDescription: "午餐", timestamp: TestDataFactory.daysAgo(2))
        
        context.insert(record1)
        context.insert(record2)
        
        try await service.deduplicateMealRecords(context: context)
        
        let descriptor = FetchDescriptor<MealRecord>()
        let records = try context.fetch(descriptor)
        
        #expect(records.count == 2)
    }
    
    @Test("饮食记录去重 - 有重复")
    func testDeduplicateMealRecordsWithDuplicates() async throws {
        let context = try TestDataFactory.createMockModelContext()
        let service = DataDeduplicationService()
        
        let timestamp = Date.now
        let record1 = TestDataFactory.createMealRecord(mealDescription: "早餐", timestamp: timestamp)
        let record2 = TestDataFactory.createMealRecord(mealDescription: "早餐", timestamp: timestamp) // 重复
        
        context.insert(record1)
        context.insert(record2)
        
        try await service.deduplicateMealRecords(context: context)
        
        let descriptor = FetchDescriptor<MealRecord>()
        let records = try context.fetch(descriptor)
        
        #expect(records.count == 1)
    }
    
    // MARK: - 批量去重测试
    
    @Test("批量去重")
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
        
        try await service.deduplicateAll(context: context)
        
        let glucoseDescriptor = FetchDescriptor<GlucoseRecord>()
        let glucoseRecords = try context.fetch(glucoseDescriptor)
        #expect(glucoseRecords.count == 1)
        
        let medDescriptor = FetchDescriptor<MedicationRecord>()
        let medRecords = try context.fetch(medDescriptor)
        #expect(medRecords.count == 1)
    }
}
