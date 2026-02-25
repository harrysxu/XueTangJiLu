//
//  TestDataFactory.swift
//  XueTangJiLuTests
//
//  Created by AI Assistant on 2026/2/23.
//

import Foundation
import SwiftData
@testable import XueTangJiLu

/// 测试数据工厂，用于快速创建测试所需的数据对象
enum TestDataFactory {
    
    // MARK: - ModelContext
    
    /// 创建内存模型容器，用于测试（不会持久化到磁盘）
    static func createMockModelContext() throws -> ModelContext {
        let schema = Schema([
            GlucoseRecord.self,
            MealRecord.self,
            MedicationRecord.self,
            UserSettings.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }
    
    // MARK: - GlucoseRecord
    
    /// 创建血糖记录
    static func createGlucoseRecord(
        value: Double = 5.6,
        timestamp: Date = .now,
        sceneTagId: String = "beforeBreakfast",
        note: String? = nil,
        source: String = "manual"
    ) -> GlucoseRecord {
        return GlucoseRecord(
            value: value,
            timestamp: timestamp,
            sceneTagId: sceneTagId,
            note: note,
            source: source
        )
    }
    
    /// 创建一组血糖记录（用于测试列表和统计）
    static func createGlucoseRecords(
        count: Int,
        startDate: Date = Date().addingTimeInterval(-86400 * 7),
        valueRange: ClosedRange<Double> = 4.0...10.0
    ) -> [GlucoseRecord] {
        var records: [GlucoseRecord] = []
        let timeInterval = abs(startDate.timeIntervalSinceNow) / Double(count)
        
        for i in 0..<count {
            let timestamp = startDate.addingTimeInterval(timeInterval * Double(i))
            let value = Double.random(in: valueRange)
            let record = createGlucoseRecord(
                value: value,
                timestamp: timestamp,
                sceneTagId: MealContext.allCases.randomElement()?.rawValue ?? "beforeBreakfast"
            )
            records.append(record)
        }
        
        return records
    }
    
    // MARK: - MealRecord
    
    /// 创建饮食记录
    static func createMealRecord(
        carbLevel: CarbLevel = .medium,
        mealDescription: String = "午餐",
        photoData: Data? = nil,
        timestamp: Date = .now,
        note: String? = nil
    ) -> MealRecord {
        return MealRecord(
            carbLevel: carbLevel,
            mealDescription: mealDescription,
            photoData: photoData,
            timestamp: timestamp,
            note: note
        )
    }
    
    // MARK: - MedicationRecord
    
    /// 创建用药记录
    static func createMedicationRecord(
        medicationType: MedicationType = .rapidInsulin,
        name: String = "诺和锐",
        dosage: Double = 4.0,
        timestamp: Date = .now,
        note: String? = nil
    ) -> MedicationRecord {
        return MedicationRecord(
            medicationType: medicationType,
            name: name,
            dosage: dosage,
            timestamp: timestamp,
            note: note
        )
    }
    
    // MARK: - UserSettings
    
    /// 创建用户设置
    static func createUserSettings(
        preferredUnit: GlucoseUnit = .mmolL,
        hasCompletedOnboarding: Bool = true,
        healthKitSyncEnabled: Bool = false
    ) -> UserSettings {
        let settings = UserSettings()
        settings.preferredUnit = preferredUnit
        settings.hasCompletedOnboarding = hasCompletedOnboarding
        settings.healthKitSyncEnabled = healthKitSyncEnabled
        return settings
    }
    
    // MARK: - Dates
    
    /// 创建特定时间的日期（用于测试TagEngine等）
    static func createDate(hour: Int, minute: Int = 0, second: Int = 0) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        components.hour = hour
        components.minute = minute
        components.second = second
        return Calendar.current.date(from: components) ?? .now
    }
    
    /// 创建指定天数之前的日期
    static func daysAgo(_ days: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
    }
    
    /// 创建指定小时之前的日期
    static func hoursAgo(_ hours: Int) -> Date {
        return Calendar.current.date(byAdding: .hour, value: -hours, to: .now) ?? .now
    }
    
    // MARK: - Test Data Sets
    
    /// 创建一周的测试数据（包含血糖、饮食、用药）
    static func createWeekTestData() -> (glucose: [GlucoseRecord], meals: [MealRecord], medications: [MedicationRecord]) {
        var glucose: [GlucoseRecord] = []
        var meals: [MealRecord] = []
        var medications: [MedicationRecord] = []
        
        for day in 0..<7 {
            let dayStart = daysAgo(day)
            
            // 每天4次血糖记录
            glucose.append(createGlucoseRecord(value: 5.5, timestamp: dayStart.addingTimeInterval(7 * 3600), sceneTagId: "beforeBreakfast"))
            glucose.append(createGlucoseRecord(value: 8.2, timestamp: dayStart.addingTimeInterval(9 * 3600), sceneTagId: "afterBreakfast"))
            glucose.append(createGlucoseRecord(value: 6.1, timestamp: dayStart.addingTimeInterval(12 * 3600), sceneTagId: "beforeLunch"))
            glucose.append(createGlucoseRecord(value: 7.8, timestamp: dayStart.addingTimeInterval(19 * 3600), sceneTagId: "afterDinner"))
            
            // 每天2次饮食记录
            meals.append(createMealRecord(carbLevel: .medium, mealDescription: "早餐", timestamp: dayStart.addingTimeInterval(8 * 3600)))
            meals.append(createMealRecord(carbLevel: .high, mealDescription: "午餐", timestamp: dayStart.addingTimeInterval(12 * 3600)))
            
            // 每天1次用药记录
            medications.append(createMedicationRecord(medicationType: .rapidInsulin, name: "诺和锐", dosage: 4.0, timestamp: dayStart.addingTimeInterval(8 * 3600)))
        }
        
        return (glucose, meals, medications)
    }
}
