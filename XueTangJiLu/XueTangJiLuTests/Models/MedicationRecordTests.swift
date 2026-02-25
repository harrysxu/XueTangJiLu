//
//  MedicationRecordTests.swift
//  XueTangJiLuTests
//
//  Created by AI Assistant on 2026/2/23.
//

import Testing
import Foundation
@testable import XueTangJiLu

struct MedicationRecordTests {
    
    // MARK: - 初始化测试
    
    @Test("基本初始化")
    func testInitialization() {
        let record = MedicationRecord(
            medicationType: .rapidInsulin,
            name: "诺和锐",
            dosage: 4.0
        )
        
        #expect(record.medicationType == .rapidInsulin)
        #expect(record.name == "诺和锐")
        #expect(record.dosage == 4.0)
    }
    
    @Test("完整初始化")
    func testFullInitialization() {
        let timestamp = Date.now
        let record = MedicationRecord(
            medicationType: .longInsulin,
            name: "来得时",
            dosage: 8.0,
            timestamp: timestamp,
            note: "睡前注射"
        )
        
        #expect(record.medicationType == .longInsulin)
        #expect(record.name == "来得时")
        #expect(record.dosage == 8.0)
        #expect(record.timestamp == timestamp)
        #expect(record.note == "睡前注射")
    }
    
    // MARK: - 药物类型测试
    
    @Test("药物类型 - 速效胰岛素")
    func testMedicationTypeRapid() {
        let record = MedicationRecord(medicationType: .rapidInsulin, name: "诺和锐", dosage: 4.0)
        
        #expect(record.medicationType == .rapidInsulin)
    }
    
    @Test("药物类型 - 长效胰岛素")
    func testMedicationTypeLong() {
        let record = MedicationRecord(medicationType: .longInsulin, name: "来得时", dosage: 8.0)
        
        #expect(record.medicationType == .longInsulin)
    }
    
    // MARK: - 剂量显示测试
    
    @Test("剂量显示格式化")
    func testDisplayDosage() {
        let record = MedicationRecord(medicationType: .rapidInsulin, name: "诺和锐", dosage: 4.5)
        
        let display = record.displayDosage
        #expect(display.contains("4.5"))
        #expect(display.contains("单位") || display.contains("U"))
    }
    
    @Test("整数剂量显示")
    func testDisplayDosageInteger() {
        let record = MedicationRecord(medicationType: .rapidInsulin, name: "诺和锐", dosage: 4.0)
        
        let display = record.displayDosage
        #expect(display.contains("4"))
    }
    
    // MARK: - 去重测试
    
    @Test("重复记录判断 - 相同")
    func testIsDuplicateSame() {
        let timestamp = Date.now
        let record1 = MedicationRecord(
            medicationType: .rapidInsulin,
            name: "诺和锐",
            dosage: 4.0,
            timestamp: timestamp
        )
        let record2 = MedicationRecord(
            medicationType: .rapidInsulin,
            name: "诺和锐",
            dosage: 4.0,
            timestamp: timestamp
        )
        
        #expect(record1.isDuplicate(of: record2))
    }
    
    @Test("重复记录判断 - 不同")
    func testIsDuplicateDifferent() {
        let record1 = MedicationRecord(
            medicationType: .rapidInsulin,
            name: "诺和锐",
            dosage: 4.0,
            timestamp: Date.now
        )
        let record2 = MedicationRecord(
            medicationType: .longInsulin,
            name: "来得时",
            dosage: 8.0,
            timestamp: Date.now.addingTimeInterval(3600)
        )
        
        #expect(!record1.isDuplicate(of: record2))
    }
    
    // MARK: - 冲突解决测试
    
    @Test("冲突解决 - 保留较早创建的")
    func testConflictResolution() {
        let earlier = Date.now.addingTimeInterval(-100)
        let later = Date.now
        
        var record1 = MedicationRecord(medicationType: .rapidInsulin, name: "诺和锐", dosage: 4.0)
        record1.createdAt = earlier
        
        var record2 = MedicationRecord(medicationType: .rapidInsulin, name: "诺和锐", dosage: 4.0)
        record2.createdAt = later
        
        let resolved = MedicationRecord.resolveConflict(between: record1, and: record2)
        
        #expect(resolved.createdAt == earlier)
    }
}
