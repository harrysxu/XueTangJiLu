//
//  MealRecordTests.swift
//  XueTangJiLuTests
//
//  Created by AI Assistant on 2026/2/23.
//

import Testing
import Foundation
@testable import XueTangJiLu

struct MealRecordTests {
    
    // MARK: - 初始化测试
    
    @Test("基本初始化")
    func testInitialization() {
        let record = MealRecord(
            carbLevel: .medium,
            mealDescription: "午餐"
        )
        
        #expect(record.carbLevel == .medium)
        #expect(record.mealDescription == "午餐")
        #expect(record.photoData == nil)
    }
    
    @Test("完整初始化")
    func testFullInitialization() {
        let timestamp = Date.now
        let photoData = Data([0x01, 0x02, 0x03])
        
        let record = MealRecord(
            carbLevel: .high,
            mealDescription: "晚餐",
            photoData: photoData,
            timestamp: timestamp,
            note: "吃了火锅"
        )
        
        #expect(record.carbLevel == .high)
        #expect(record.mealDescription == "晚餐")
        #expect(record.photoData == photoData)
        #expect(record.timestamp == timestamp)
        #expect(record.note == "吃了火锅")
    }
    
    // MARK: - 碳水等级测试
    
    @Test("碳水等级 - 低")
    func testCarbLevelLow() {
        let record = MealRecord(carbLevel: .low, mealDescription: "沙拉")
        
        #expect(record.carbLevel == .low)
    }
    
    @Test("碳水等级 - 中")
    func testCarbLevelMedium() {
        let record = MealRecord(carbLevel: .medium, mealDescription: "午餐")
        
        #expect(record.carbLevel == .medium)
    }
    
    @Test("碳水等级 - 高")
    func testCarbLevelHigh() {
        let record = MealRecord(carbLevel: .high, mealDescription: "米饭")
        
        #expect(record.carbLevel == .high)
    }
    
    // MARK: - 照片处理测试
    
    @Test("有照片判断")
    func testHasPhoto() {
        let photoData = Data([0x01, 0x02, 0x03])
        let record = MealRecord(
            carbLevel: .medium,
            mealDescription: "午餐",
            photoData: photoData
        )
        
        #expect(record.hasPhoto == true)
    }
    
    @Test("无照片判断")
    func testHasNoPhoto() {
        let record = MealRecord(
            carbLevel: .medium,
            mealDescription: "午餐"
        )
        
        #expect(record.hasPhoto == false)
    }
    
    // MARK: - 去重测试
    
    @Test("重复记录判断 - 相同")
    func testIsDuplicateSame() {
        let timestamp = Date.now
        let record1 = MealRecord(
            carbLevel: .medium,
            mealDescription: "午餐",
            timestamp: timestamp
        )
        let record2 = MealRecord(
            carbLevel: .medium,
            mealDescription: "午餐",
            timestamp: timestamp
        )
        
        #expect(record1.isDuplicate(of: record2))
    }
    
    @Test("重复记录判断 - 不同")
    func testIsDuplicateDifferent() {
        let record1 = MealRecord(
            carbLevel: .medium,
            mealDescription: "午餐",
            timestamp: Date.now
        )
        let record2 = MealRecord(
            carbLevel: .high,
            mealDescription: "晚餐",
            timestamp: Date.now.addingTimeInterval(3600)
        )
        
        #expect(!record1.isDuplicate(of: record2))
    }
    
    // MARK: - 冲突解决测试
    
    @Test("冲突解决 - 优先保留有照片的")
    func testConflictResolutionWithPhoto() {
        let photoData = Data([0x01, 0x02, 0x03])
        
        let recordWithPhoto = MealRecord(
            carbLevel: .medium,
            mealDescription: "午餐",
            photoData: photoData
        )
        
        let recordWithoutPhoto = MealRecord(
            carbLevel: .medium,
            mealDescription: "午餐"
        )
        
        let resolved = MealRecord.resolveConflict(between: recordWithPhoto, and: recordWithoutPhoto)
        
        #expect(resolved.hasPhoto == true)
    }
}
