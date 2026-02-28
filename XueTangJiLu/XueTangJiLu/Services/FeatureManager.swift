//
//  FeatureManager.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/26.
//

import Foundation

/// 功能权限管理器
struct FeatureManager {
    
    // MARK: - Constants
    
    /// 免费版每日记录上限
    private static let freeDailyRecordLimit = 5
    
    /// 免费版历史数据查看天数限制
    private static let freeHistoryDaysLimit = 7
    
    // MARK: - Feature Access Control
    
    /// 检查是否可以访问某个功能
    static func canAccessFeature(_ feature: Feature, isPremium: Bool) -> Bool {
        // 付费用户可以访问所有功能
        if isPremium {
            return true
        }
        
        // 免费用户的功能限制
        switch feature {
        case .unlimitedRecords:
            return false
        case .iCloudSync:
            return false
        case .pdfExport:
            return false
        case .csvExport:
            return false
        case .appleWatch:
            return false
        case .advancedCharts:
            return false
        case .medicationTracking:
            return true
        }
    }
    
    /// 获取每日记录上限
    /// - Parameter isPremium: 是否是付费用户
    /// - Returns: 记录上限，nil 表示无限制
    static func dailyRecordLimit(isPremium: Bool) -> Int? {
        return isPremium ? nil : freeDailyRecordLimit
    }
    
    /// 获取历史数据查看天数限制
    /// - Parameter isPremium: 是否是付费用户
    /// - Returns: 天数限制，nil 表示无限制
    static func historyDaysLimit(isPremium: Bool) -> Int? {
        return isPremium ? nil : freeHistoryDaysLimit
    }
    
    // MARK: - Feature Descriptions
    
    /// 获取功能解锁提示文本
    static func unlockPrompt(for feature: Feature) -> String {
        switch feature {
        case .unlimitedRecords:
            return String(localized: "feature.unlock.unlimited_records")
        case .iCloudSync:
            return String(localized: "feature.unlock.icloud_sync")
        case .pdfExport:
            return String(localized: "feature.unlock.pdf_export")
        case .csvExport:
            return String(localized: "feature.unlock.csv_export")
        case .appleWatch:
            return String(localized: "feature.unlock.apple_watch")
        case .advancedCharts:
            return String(localized: "feature.unlock.advanced_charts")
        case .medicationTracking:
            return ""
        }
    }
    
    /// 获取所有高级功能列表
    static func premiumFeatures() -> [Feature] {
        return [
            .unlimitedRecords,
            .iCloudSync,
            .pdfExport,
            .csvExport,
            .appleWatch,
            .advancedCharts
        ]
    }
    
    /// 检查今日记录是否已达上限
    /// - Parameters:
    ///   - todayRecordsCount: 今日已有记录数
    ///   - isPremium: 是否是付费用户
    /// - Returns: 是否已达上限
    static func hasReachedDailyLimit(todayRecordsCount: Int, isPremium: Bool) -> Bool {
        guard let limit = dailyRecordLimit(isPremium: isPremium) else {
            return false  // 无限制
        }
        return todayRecordsCount >= limit
    }
    
    /// 获取剩余可用记录数
    /// - Parameters:
    ///   - todayRecordsCount: 今日已有记录数
    ///   - isPremium: 是否是付费用户
    /// - Returns: 剩余记录数，nil 表示无限制
    static func remainingRecordsToday(todayRecordsCount: Int, isPremium: Bool) -> Int? {
        guard let limit = dailyRecordLimit(isPremium: isPremium) else {
            return nil  // 无限制
        }
        return max(0, limit - todayRecordsCount)
    }
}

// MARK: - Feature Description Extensions

extension Feature {
    /// 功能的详细描述
    var detailedDescription: String {
        switch self {
        case .unlimitedRecords:
            return String(localized: "feature.description.unlimited_records")
        case .iCloudSync:
            return String(localized: "feature.description.icloud_sync")
        case .pdfExport:
            return String(localized: "feature.description.pdf_export")
        case .csvExport:
            return String(localized: "feature.description.csv_export")
        case .appleWatch:
            return String(localized: "feature.description.apple_watch")
        case .advancedCharts:
            return String(localized: "feature.description.advanced_charts")
        case .medicationTracking:
            return String(localized: "feature.description.medication_tracking")
        }
    }
}
