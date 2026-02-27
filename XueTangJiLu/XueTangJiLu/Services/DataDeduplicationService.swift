//
//  DataDeduplicationService.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/22.
//

import Foundation
import SwiftData

/// 数据去重服务
/// 使用 @MainActor 确保 ModelContext 始终在主队列上操作，避免线程安全警告
@MainActor
final class DataDeduplicationService {
    
    // MARK: - Methods
    
    /// 去重所有血糖记录
    func deduplicateGlucoseRecords(context: ModelContext) throws {
        let descriptor = FetchDescriptor<GlucoseRecord>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        let allRecords = try context.fetch(descriptor)
        #if DEBUG
        print("🔍 [去重] 开始检查血糖记录，总数: \(allRecords.count)")
        #endif
        
        // 按去重键分组
        let grouped = Dictionary(grouping: allRecords) { $0.deduplicationKey }
        
        var deletedCount = 0
        var keptCount = 0
        
        for (key, duplicates) in grouped where duplicates.count > 1 {
            print("⚠️ [去重] 发现重复组: key=\(key), 数量=\(duplicates.count)")
            
            // 按创建时间排序，保留最早创建的
            // 注意：createdAt 在 iCloud 同步后可能会变化，这是一个已知问题
            let sorted = duplicates.sorted { $0.createdAt < $1.createdAt }
            
            // 保留第一条
            if let kept = sorted.first {
                print("  ✅ 保留: value=\(kept.value), timestamp=\(kept.timestamp), createdAt=\(kept.createdAt)")
                keptCount += 1
            }
            
            // 删除其余的重复项
            for record in sorted.dropFirst() {
                print("  ❌ 删除: value=\(record.value), timestamp=\(record.timestamp), createdAt=\(record.createdAt)")
                context.delete(record)
                deletedCount += 1
            }
        }
        
        if deletedCount > 0 {
            try context.save()
            print("✅ [去重] 血糖记录去重完成：保留 \(keptCount) 条，删除 \(deletedCount) 条重复记录")
        } else {
            print("✅ [去重] 血糖记录无重复，总数: \(allRecords.count)")
        }
    }
    
    /// 去重所有用药记录
    func deduplicateMedicationRecords(context: ModelContext) throws {
        let descriptor = FetchDescriptor<MedicationRecord>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        let allRecords = try context.fetch(descriptor)
        print("🔍 [去重] 开始检查用药记录，总数: \(allRecords.count)")
        
        var deletedCount = 0
        var processedGroups = Set<String>()
        
        for record in allRecords {
            let groupKey = "\(record.timestamp.timeIntervalSince1970)_\(record.medicationType.rawValue)_\(record.name)_\(record.dosage)"
            
            if processedGroups.contains(groupKey) {
                // 这是重复记录
                print("  ❌ 删除重复: \(record.name) \(record.dosage), timestamp=\(record.timestamp)")
                context.delete(record)
                deletedCount += 1
            } else {
                processedGroups.insert(groupKey)
            }
        }
        
        if deletedCount > 0 {
            try context.save()
            print("✅ [去重] 用药记录去重完成：删除了 \(deletedCount) 条重复记录")
        } else {
            print("✅ [去重] 用药记录无重复，总数: \(allRecords.count)")
        }
    }
    
    /// 去重所有饮食记录
    func deduplicateMealRecords(context: ModelContext) throws {
        let descriptor = FetchDescriptor<MealRecord>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        let allRecords = try context.fetch(descriptor)
        print("🔍 [去重] 开始检查饮食记录，总数: \(allRecords.count)")
        
        var deletedCount = 0
        var processedGroups = Set<String>()
        
        for record in allRecords {
            let groupKey = "\(record.timestamp.timeIntervalSince1970)_\(record.mealDescription)_\(record.carbLevel.rawValue)"
            
            if processedGroups.contains(groupKey) {
                // 这是重复记录
                print("  ❌ 删除重复: \(record.mealDescription), timestamp=\(record.timestamp)")
                context.delete(record)
                deletedCount += 1
            } else {
                processedGroups.insert(groupKey)
            }
        }
        
        if deletedCount > 0 {
            try context.save()
            print("✅ [去重] 饮食记录去重完成：删除了 \(deletedCount) 条重复记录")
        } else {
            print("✅ [去重] 饮食记录无重复，总数: \(allRecords.count)")
        }
    }
    
    /// 去重所有用户设置（保留定制化程度最高的）
    /// - Returns: 返回保留的UserSettings实例
    @discardableResult
    func deduplicateUserSettings(context: ModelContext) throws -> UserSettings {
        let descriptor = FetchDescriptor<UserSettings>()
        let allSettings = try context.fetch(descriptor)
        
        // 如果没有设置，创建一个默认的
        if allSettings.isEmpty {
            let newSettings = UserSettings()
            context.insert(newSettings)
            try context.save()
            print("✅ 创建了默认UserSettings实例")
            return newSettings
        }
        
        // 如果只有一个，直接返回
        if allSettings.count == 1 {
            return allSettings[0]
        }
        
        // 如果有多个，执行去重合并
        let result = UserSettings.deduplicate(allSettings)
        
        for duplicate in result.toDelete {
            context.delete(duplicate)
        }
        
        try context.save()
        print("✅ UserSettings去重完成：合并了 \(result.toDelete.count) 个重复实例，保留1个")
        return result.keep
    }
    
    /// 执行完整的数据去重
    func deduplicateAll(context: ModelContext) throws {
        print("🔄 开始数据去重...")
        
        try deduplicateUserSettings(context: context)
        try deduplicateGlucoseRecords(context: context)
        try deduplicateMedicationRecords(context: context)
        try deduplicateMealRecords(context: context)
        
        print("✅ 数据去重完成")
    }
}
