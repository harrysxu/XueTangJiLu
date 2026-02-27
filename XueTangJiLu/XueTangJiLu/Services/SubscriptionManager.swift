//
//  SubscriptionManager.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/26.
//

import Foundation
import SwiftUI

/// 订阅状态管理器
@MainActor
@Observable
class SubscriptionManager {
    
    // MARK: - Properties
    
    /// 用户是否是付费会员
    var isPremiumUser: Bool {
        didSet {
            UserDefaults.standard.set(isPremiumUser, forKey: "is_premium_user")
        }
    }
    
    /// 当前订阅类型
    var subscriptionType: SubscriptionType? {
        didSet {
            if let type = subscriptionType {
                UserDefaults.standard.set(type.rawValue, forKey: "subscription_type")
            } else {
                UserDefaults.standard.removeObject(forKey: "subscription_type")
            }
        }
    }
    
    // MARK: - Stored Properties
    
    /// 首次购买日期（用于早鸟价保护）
    @ObservationIgnored
    @AppStorage("first_purchase_date") private var firstPurchaseDateString: String?
    
    /// 订阅过期时间
    @ObservationIgnored
    @AppStorage("subscription_expiry_date") private var expiryDateString: String?
    
    // MARK: - Computed Properties
    
    /// 首次购买日期
    var firstPurchaseDate: Date? {
        guard let dateString = firstPurchaseDateString else { return nil }
        return ISO8601DateFormatter().date(from: dateString)
    }
    
    /// 订阅过期日期
    var expiryDate: Date? {
        guard let dateString = expiryDateString else { return nil }
        return ISO8601DateFormatter().date(from: dateString)
    }
    
    /// 是否是早鸟用户（首发优惠用户）
    var isEarlyBirdUser: Bool {
        guard let firstDate = firstPurchaseDate else { return false }
        
        // 2026年3月31日前购买的算早鸟用户
        let earlyBirdDeadline = Calendar.current.date(from: DateComponents(
            year: 2026, month: 3, day: 31, hour: 23, minute: 59, second: 59
        ))!
        
        return firstDate <= earlyBirdDeadline
    }
    
    /// 订阅是否有效
    var isSubscriptionActive: Bool {
        guard isPremiumUser else { return false }
        
        // 买断用户永久有效
        if subscriptionType == .lifetime {
            return true
        }
        
        // 检查订阅是否过期
        if let expiry = expiryDate {
            return Date.now <= expiry
        }
        
        // 如果没有过期时间记录，默认有效（由 StoreKit 管理）
        return true
    }
    
    /// 订阅状态描述
    var statusDescription: String {
        if !isPremiumUser {
            return String(localized: "subscription.status.free")
        }
        
        guard let type = subscriptionType else {
            return String(localized: "subscription.status.active")
        }
        
        return type.localizedName
    }
    
    // MARK: - Initialization
    
    init() {
        // 从 UserDefaults 恢复状态
        self.isPremiumUser = UserDefaults.standard.bool(forKey: "is_premium_user")
        
        if let typeString = UserDefaults.standard.string(forKey: "subscription_type"),
           let type = SubscriptionType(rawValue: typeString) {
            self.subscriptionType = type
        } else {
            self.subscriptionType = nil
        }
        
        #if DEBUG
        print("📋 订阅管理器初始化:")
        print("  - 付费用户: \(isPremiumUser)")
        print("  - 订阅类型: \(subscriptionType?.rawValue ?? "无")")
        print("  - 早鸟用户: \(isEarlyBirdUser)")
        #endif
    }
    
    // MARK: - Public Methods
    
    /// 更新订阅状态（从 StoreManager 调用）
    func updateSubscriptionStatus(from storeManager: StoreManager) {
        let wasPremium = isPremiumUser
        
        isPremiumUser = storeManager.isPremiumUser()
        subscriptionType = storeManager.currentSubscriptionType()
        setExpiryDate(storeManager.latestExpirationDate)
        
        if isPremiumUser && firstPurchaseDateString == nil {
            recordFirstPurchase()
        }
        
        if !wasPremium && isPremiumUser {
            #if DEBUG
            print("🎉 用户升级为付费会员: \(subscriptionType?.rawValue ?? "unknown")")
            #endif
        }
    }
    
    /// 记录首次购买时间
    func recordFirstPurchase() {
        if firstPurchaseDateString == nil {
            let dateString = ISO8601DateFormatter().string(from: Date.now)
            firstPurchaseDateString = dateString
            
            #if DEBUG
            print("📅 记录首次购买时间: \(Date.now)")
            #endif
        }
    }
    
    /// 设置订阅过期时间
    func setExpiryDate(_ date: Date?) {
        if let date = date {
            expiryDateString = ISO8601DateFormatter().string(from: date)
        } else {
            expiryDateString = nil
        }
    }
    
    /// 清除订阅状态（用于测试或重置）
    func clearSubscriptionStatus() {
        isPremiumUser = false
        subscriptionType = nil
        firstPurchaseDateString = nil
        expiryDateString = nil
        
        #if DEBUG
        print("🧹 清除订阅状态")
        #endif
    }
    
    /// 获取订阅信息摘要
    func getSubscriptionSummary() -> String {
        if !isPremiumUser {
            return String(localized: "subscription.summary.free")
        }
        
        var summary = statusDescription
        
        if let type = subscriptionType {
            switch type {
            case .lifetime:
                summary += " • " + String(localized: "subscription.summary.lifetime")
            case .yearly, .quarterly, .monthly:
                if let expiry = expiryDate {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    summary += " • " + String(localized: "subscription.summary.expires") + " \(formatter.string(from: expiry))"
                }
            }
        }
        
        if isEarlyBirdUser {
            summary += " • " + String(localized: "subscription.summary.early_bird")
        }
        
        return summary
    }
}
