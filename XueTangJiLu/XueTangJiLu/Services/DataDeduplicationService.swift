//
//  DataDeduplicationService.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/22.
//

import Foundation
import SwiftData

/// 数据去重服务
actor DataDeduplicationService {
    
    // MARK: - Methods
    
    /// 去重所有血糖记录
    func deduplicateGlucoseRecords(context: ModelContext) async throws {
        let descriptor = FetchDescriptor<GlucoseRecord>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        let allRecords = try context.fetch(descriptor)
        
        // 按去重键分组
        let grouped = Dictionary(grouping: allRecords) { $0.deduplicationKey }
        
        var deletedCount = 0
        
        for (_, duplicates) in grouped where duplicates.count > 1 {
            // 按创建时间排序，保留最早创建的
            let sorted = duplicates.sorted { $0.createdAt < $1.createdAt }
            
            // 删除其余的重复项
            for record in sorted.dropFirst() {
                context.delete(record)
                deletedCount += 1
            }
        }
        
        if deletedCount > 0 {
            try context.save()
            print("去重完成：删除了 \(deletedCount) 条重复血糖记录")
        }
    }
    
    /// 去重所有用药记录
    func deduplicateMedicationRecords(context: ModelContext) async throws {
        let descriptor = FetchDescriptor<MedicationRecord>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        let allRecords = try context.fetch(descriptor)
        
        var deletedCount = 0
        var processedGroups = Set<String>()
        
        for record in allRecords {
            let groupKey = "\(record.timestamp.timeIntervalSince1970)_\(record.medicationType.rawValue)_\(record.name)_\(record.dosage)"
            
            if processedGroups.contains(groupKey) {
                // 这是重复记录
                context.delete(record)
                deletedCount += 1
            } else {
                processedGroups.insert(groupKey)
            }
        }
        
        if deletedCount > 0 {
            try context.save()
            print("去重完成：删除了 \(deletedCount) 条重复用药记录")
        }
    }
    
    /// 去重所有饮食记录
    func deduplicateMealRecords(context: ModelContext) async throws {
        let descriptor = FetchDescriptor<MealRecord>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        let allRecords = try context.fetch(descriptor)
        
        var deletedCount = 0
        var processedGroups = Set<String>()
        
        for record in allRecords {
            let groupKey = "\(record.timestamp.timeIntervalSince1970)_\(record.mealDescription)_\(record.carbLevel.rawValue)"
            
            if processedGroups.contains(groupKey) {
                // 这是重复记录
                context.delete(record)
                deletedCount += 1
            } else {
                processedGroups.insert(groupKey)
            }
        }
        
        if deletedCount > 0 {
            try context.save()
            print("去重完成：删除了 \(deletedCount) 条重复饮食记录")
        }
    }
    
    /// 去重所有用户设置（保留定制化程度最高的）
    func deduplicateUserSettings(context: ModelContext) async throws {
        let descriptor = FetchDescriptor<UserSettings>()
        let allSettings = try context.fetch(descriptor)
        
        guard allSettings.count > 1 else { return }
        
        let result = UserSettings.deduplicate(allSettings)
        
        for duplicate in result.toDelete {
            context.delete(duplicate)
        }
        
        try context.save()
        print("去重完成：合并了 \(result.toDelete.count) 个重复的用户设置")
    }
    
    /// 执行完整的数据去重
    func deduplicateAll(context: ModelContext) async throws {
        print("开始数据去重...")
        
        try await deduplicateGlucoseRecords(context: context)
        try await deduplicateMedicationRecords(context: context)
        try await deduplicateMealRecords(context: context)
        try await deduplicateUserSettings(context: context)
        
        print("数据去重完成")
    }
    
    /// 定期执行去重（建议在应用启动时或后台任务中调用）
    func performPeriodicDeduplication(context: ModelContext, interval: TimeInterval = 3600) async {
        while true {
            do {
                try await Task.sleep(for: .seconds(interval))
                try await deduplicateAll(context: context)
            } catch {
                print("定期去重失败: \(error)")
            }
        }
    }
}
