//
//  IAPProduct.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/26.
//

import Foundation
import StoreKit

/// IAP 产品 ID 枚举
enum IAPProduct: String, CaseIterable {
    case monthly = "com.xxl.xuetang.monthly"
    case quarterly = "com.xxl.xuetang.quarterly"
    case yearly = "com.xxl.xuetang.yearly"
    case lifetime = "com.xxl.xuetang.lifetime"
    
    /// 本地化标题
    var localizedTitle: String {
        switch self {
        case .monthly:
            return String(localized: "subscription.monthly")
        case .quarterly:
            return String(localized: "subscription.quarterly")
        case .yearly:
            return String(localized: "subscription.yearly")
        case .lifetime:
            return String(localized: "subscription.lifetime")
        }
    }
    
    /// 本地化描述
    var localizedDescription: String {
        switch self {
        case .monthly:
            return String(localized: "subscription.monthly.description")
        case .quarterly:
            return String(localized: "subscription.quarterly.description")
        case .yearly:
            return String(localized: "subscription.yearly.description")
        case .lifetime:
            return String(localized: "subscription.lifetime.description")
        }
    }
    
    /// 产品图标
    var icon: String {
        switch self {
        case .monthly:
            return "calendar"
        case .quarterly:
            return "calendar.badge.clock"
        case .yearly:
            return "star.fill"
        case .lifetime:
            return "crown.fill"
        }
    }
    
    /// 推荐标记
    var isRecommended: Bool {
        return self == .yearly
    }
    
    /// 是否是订阅类型
    var isSubscription: Bool {
        return self != .lifetime
    }
    
    /// 订阅时长描述
    var durationDescription: String {
        switch self {
        case .monthly:
            return String(localized: "subscription.duration.monthly")
        case .quarterly:
            return String(localized: "subscription.duration.quarterly")
        case .yearly:
            return String(localized: "subscription.duration.yearly")
        case .lifetime:
            return String(localized: "subscription.duration.lifetime")
        }
    }
    
    /// 折算月数（用于计算每月均价）
    var monthCount: Int {
        switch self {
        case .monthly: return 1
        case .quarterly: return 3
        case .yearly: return 12
        case .lifetime: return 0
        }
    }
}

/// 功能枚举
enum Feature: String, CaseIterable {
    case unlimitedRecords
    case iCloudSync
    case pdfExport
    case csvExport
    case appleWatch
    case advancedCharts
    case medicationTracking
    
    /// 功能本地化名称
    var localizedName: String {
        switch self {
        case .unlimitedRecords:
            return String(localized: "feature.unlimited_records")
        case .iCloudSync:
            return String(localized: "feature.icloud_sync")
        case .pdfExport:
            return String(localized: "feature.pdf_export")
        case .csvExport:
            return String(localized: "feature.csv_export")
        case .appleWatch:
            return String(localized: "feature.apple_watch")
        case .advancedCharts:
            return String(localized: "feature.advanced_charts")
        case .medicationTracking:
            return String(localized: "feature.medication_tracking")
        }
    }
    
    /// 功能图标
    var icon: String {
        switch self {
        case .unlimitedRecords:
            return "infinity"
        case .iCloudSync:
            return "icloud.fill"
        case .pdfExport:
            return "doc.fill"
        case .csvExport:
            return "tablecells"
        case .appleWatch:
            return "applewatch"
        case .advancedCharts:
            return "chart.xyaxis.line"
        case .medicationTracking:
            return "pill.fill"
        }
    }
}

/// 订阅类型
enum SubscriptionType: String, Codable {
    case monthly
    case quarterly
    case yearly
    case lifetime
    
    var localizedName: String {
        switch self {
        case .monthly:
            return String(localized: "subscription.monthly")
        case .quarterly:
            return String(localized: "subscription.quarterly")
        case .yearly:
            return String(localized: "subscription.yearly")
        case .lifetime:
            return String(localized: "subscription.lifetime")
        }
    }
}
