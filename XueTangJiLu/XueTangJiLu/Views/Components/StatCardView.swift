//
//  StatCardView.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import SwiftUI

/// 统计指标卡片
struct StatCardView: View {
    let title: String         // 指标名称（如"平均血糖"）
    let value: String         // 数值（如"6.2"）
    let subtitle: String?     // 单位或参考（如"mmol/L"）
    let tintColor: Color?     // 可选的强调色

    init(title: String, value: String, subtitle: String? = nil, tintColor: Color? = nil) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.tintColor = tintColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.glucoseMetric)
                .foregroundStyle(tintColor ?? .primary)

            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppConstants.Spacing.md)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) \(value) \(subtitle ?? "")")
    }
}

#Preview {
    HStack {
        StatCardView(title: "次数", value: "4", subtitle: "今日")
        StatCardView(title: "均值", value: "6.2", subtitle: "mmol/L", tintColor: .glucoseNormal)
        StatCardView(title: "达标率", value: "75%", subtitle: "TIR")
    }
    .padding()
}
