//
//  InsightCardView.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/14.
//

import SwiftUI

/// 洞察卡片组件
struct InsightCardView: View {
    let insight: GlucoseInsight

    private var categoryColor: Color {
        switch insight.category {
        case .positive: return Color("GlucoseNormal")
        case .warning:  return Color("GlucoseHigh")
        case .info:     return Color.brandPrimary
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: AppConstants.Spacing.md) {
            // 图标
            Image(systemName: insight.icon)
                .font(.title3)
                .foregroundStyle(categoryColor)
                .frame(width: 36, height: 36)
                .background(categoryColor.opacity(0.12))
                .clipShape(Circle())

            // 内容
            VStack(alignment: .leading, spacing: AppConstants.Spacing.xs) {
                Text(insight.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(insight.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            Spacer(minLength: 0)
        }
        .padding(AppConstants.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card)
                .fill(Color.cardBackground)
        )
    }
}

#Preview {
    VStack(spacing: 12) {
        InsightCardView(insight: GlucoseInsight(
            icon: "checkmark.seal.fill",
            title: "血糖控制良好",
            description: "本周达标率 78%，已达到 70% 的推荐目标",
            category: .positive
        ))

        InsightCardView(insight: GlucoseInsight(
            icon: "fork.knife.circle.fill",
            title: "午餐后血糖偏高",
            description: "近一周有 60% 的午餐后血糖超过 10.0 mmol/L",
            category: .warning
        ))

        InsightCardView(insight: GlucoseInsight(
            icon: "clock.badge.exclamationmark.fill",
            title: "记录不够频繁",
            description: "本周平均每天仅记录 1.5 次，建议每天至少记录 3-4 次",
            category: .info
        ))
    }
    .padding()
}
