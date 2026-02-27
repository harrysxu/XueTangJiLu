//
//  SubscriptionStatusCard.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/26.
//

import SwiftUI

/// 订阅状态卡片
struct SubscriptionStatusCard: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @State private var showPaywall = false
    
    var body: some View {
        if subscriptionManager.isPremiumUser {
            // 付费用户状态卡片
            premiumStatusCard
        } else {
            // 免费用户升级卡片
            upgradePromptCard
        }
    }
    
    // MARK: - Premium Status Card
    
    private var premiumStatusCard: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
            HStack {
                Image(systemName: "crown.fill")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "subscription.status.premium"))
                        .font(.headline)
                    
                    Text(subscriptionManager.statusDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            // 订阅信息摘要
            Text(subscriptionManager.getSubscriptionSummary())
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // 管理订阅按钮
            Button {
                openSubscriptionManagement()
            } label: {
                Text(String(localized: "subscription.button.manage"))
                    .font(.subheadline)
                    .foregroundStyle(.brandPrimary)
            }
        }
        .padding(AppConstants.Spacing.lg)
        .background(
            LinearGradient(
                colors: [.yellow.opacity(0.1), .orange.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card)
                .stroke(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
    
    // MARK: - Upgrade Prompt Card
    
    private var upgradePromptCard: some View {
        Button {
            showPaywall = true
        } label: {
            HStack(spacing: AppConstants.Spacing.md) {
                // 图标
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.brandPrimary.opacity(0.2), .brandPrimary.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "crown.fill")
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.brandPrimary, .brandPrimary.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                // 文字内容
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "subscription.upgrade.title"))
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(String(localized: "subscription.upgrade.subtitle"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // 箭头
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.brandPrimary)
            }
            .padding(AppConstants.Spacing.lg)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card)
                    .stroke(Color.brandPrimary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
    
    // MARK: - Actions
    
    private func openSubscriptionManagement() {
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            #if canImport(UIKit)
            UIApplication.shared.open(url)
            #endif
        }
    }
}

/// 简洁版订阅状态徽章
struct SubscriptionBadge: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    
    var body: some View {
        if subscriptionManager.isPremiumUser {
            HStack(spacing: 4) {
                Image(systemName: "crown.fill")
                    .font(.caption2)
                Text(String(localized: "subscription.badge.pro"))
                    .font(.caption.weight(.semibold))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                LinearGradient(
                    colors: [.yellow, .orange],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundStyle(.white)
            .clipShape(Capsule())
        }
    }
}

/// 功能限制提示条
struct LimitationBanner: View {
    let limitationType: LimitationType
    @State private var showPaywall = false
    
    enum LimitationType {
        case dailyRecords(remaining: Int, total: Int)
        case historyDays(days: Int)
        
        var message: String {
            switch self {
            case .dailyRecords(let remaining, let total):
                return String(format: String(localized: "limit.banner.daily_records"), remaining, total)
            case .historyDays(let days):
                return String(format: String(localized: "limit.banner.history_days"), days)
            }
        }
        
        var icon: String {
            switch self {
            case .dailyRecords:
                return "exclamationmark.circle.fill"
            case .historyDays:
                return "clock.fill"
            }
        }
    }
    
    var body: some View {
        Button {
            showPaywall = true
        } label: {
            HStack {
                Image(systemName: limitationType.icon)
                    .foregroundStyle(.orange)
                
                Text(limitationType.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "crown.fill")
                        .font(.caption2)
                    Text(String(localized: "feature.button.upgrade"))
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(.brandPrimary)
            }
            .padding(.horizontal, AppConstants.Spacing.md)
            .padding(.vertical, AppConstants.Spacing.sm)
            .background(Color.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.input))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}

#Preview("Status Card - Premium") {
    VStack(spacing: 20) {
        SubscriptionStatusCard()
            .environment(SubscriptionManager())
        
        SubscriptionBadge()
            .environment(SubscriptionManager())
    }
    .padding()
    .background(Color.pageBackground)
}

#Preview("Status Card - Free") {
    let manager = SubscriptionManager()
    
    VStack(spacing: 20) {
        SubscriptionStatusCard()
            .environment(manager)
        
        LimitationBanner(limitationType: .dailyRecords(remaining: 2, total: 5))
        
        LimitationBanner(limitationType: .historyDays(days: 7))
    }
    .padding()
    .background(Color.pageBackground)
}
