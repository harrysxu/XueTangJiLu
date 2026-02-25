//
//  GlucoseRecordTests.swift
//  XueTangJiLuTests
//
//  Created by AI Assistant on 2026/2/23.
//

import Testing
import Foundation
@testable import XueTangJiLu

struct GlucoseRecordTests {
    
    // MARK: - 初始化测试
    
    @Test("基本初始化")
    func testInitialization() {
        let record = GlucoseRecord(value: 5.6)
        
        #expect(record.value == 5.6)
        #expect(record.source == "manual")
        #expect(record.syncedToHealthKit == false)
    }
    
    @Test("完整初始化")
    func testFullInitialization() {
        let timestamp = Date.now
        let record = GlucoseRecord(
            value: 7.2,
            timestamp: timestamp,
            sceneTagId: "beforeBreakfast",
            note: "空腹测量",
            source: "manual"
        )
        
        #expect(record.value == 7.2)
        #expect(record.timestamp == timestamp)
        #expect(record.sceneTagId == "beforeBreakfast")
        #expect(record.note == "空腹测量")
        #expect(record.source == "manual")
    }
    
    // MARK: - 单位转换测试
    
    @Test("单位转换 - mmol/L 到 mg/dL")
    func testUnitConversion() {
        let record = GlucoseRecord(value: 5.5)
        
        let mgdl = record.valueInMgDL
        #expect(abs(mgdl - 99.1) < 0.5)
    }
    
    @Test("显示值格式化 - mmol/L")
    func testDisplayValueMmolL() {
        let record = GlucoseRecord(value: 5.567)
        
        let display = record.displayValue(in: .mmolL)
        #expect(display == "5.6")
    }
    
    @Test("显示值格式化 - mg/dL")
    func testDisplayValueMgdL() {
        let record = GlucoseRecord(value: 5.5)
        
        let display = record.displayValue(in: .mgdL)
        #expect(display == "99")
    }
    
    // MARK: - 血糖等级测试
    
    @Test("血糖等级 - 通用阈值")
    func testGlucoseLevelGeneric() {
        let lowRecord = GlucoseRecord(value: 3.0)
        #expect(lowRecord.glucoseLevel == .low)
        
        let normalRecord = GlucoseRecord(value: 5.5)
        #expect(normalRecord.glucoseLevel == .normal)
        
        let highRecord = GlucoseRecord(value: 8.5)
        #expect(highRecord.glucoseLevel == .high)
        
        let veryHighRecord = GlucoseRecord(value: 12.0)
        #expect(veryHighRecord.glucoseLevel == .veryHigh)
    }
    
    // MARK: - 场景标签测试
    
    @Test("内置场景标签")
    func testBuiltInMealContext() {
        let record = GlucoseRecord(value: 5.5, sceneTagId: "beforeBreakfast")
        
        #expect(record.builtInMealContext == .beforeBreakfast)
    }
    
    @Test("自定义场景标签")
    func testCustomSceneTag() {
        let customId = UUID().uuidString
        let record = GlucoseRecord(value: 5.5, sceneTagId: customId)
        
        #expect(record.builtInMealContext == nil) // 自定义标签不应有内置映射
    }
    
    // MARK: - 去重测试
    
    @Test("去重键生成")
    func testDeduplicationKey() {
        let record = GlucoseRecord(value: 5.6, timestamp: Date.now, sceneTagId: "beforeBreakfast")
        
        let key = record.deduplicationKey
        #expect(key.contains("5.6"))
        #expect(key.contains("beforeBreakfast"))
    }
    
    @Test("重复记录判断 - 相同")
    func testIsDuplicateSame() {
        let timestamp = Date.now
        let record1 = GlucoseRecord(value: 5.6, timestamp: timestamp, sceneTagId: "beforeBreakfast")
        let record2 = GlucoseRecord(value: 5.6, timestamp: timestamp, sceneTagId: "beforeBreakfast")
        
        #expect(record1.isDuplicate(of: record2))
    }
    
    @Test("重复记录判断 - 不同")
    func testIsDuplicateDifferent() {
        let record1 = GlucoseRecord(value: 5.6, timestamp: Date.now)
        let record2 = GlucoseRecord(value: 6.2, timestamp: Date.now.addingTimeInterval(3600))
        
        #expect(!record1.isDuplicate(of: record2))
    }
    
    // MARK: - 冲突解决测试
    
    @Test("冲突解决 - 保留较早创建的")
    func testConflictResolution() {
        let earlier = Date.now.addingTimeInterval(-100)
        let later = Date.now
        
        var record1 = GlucoseRecord(value: 5.6)
        record1.createdAt = earlier
        
        var record2 = GlucoseRecord(value: 5.6)
        record2.createdAt = later
        
        let resolved = GlucoseRecord.resolveConflict(between: record1, and: record2)
        
        #expect(resolved.createdAt == earlier)
    }
}
