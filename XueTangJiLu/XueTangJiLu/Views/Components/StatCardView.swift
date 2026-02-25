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
    let metricType: MetricType? // 可选的指标类型（用于显示解释按钮）

    init(title: String, value: String, subtitle: String? = nil, tintColor: Color? = nil, metricType: MetricType? = nil) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.tintColor = tintColor
        self.metricType = metricType
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
            // 第一行：标题 + 副标题/问号图标
            HStack(spacing: 4) {
                Text(title)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                if let metricType {
                    MetricExplanationView(metricType: metricType)
                } else if let subtitle {
                    Text("(\(subtitle))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(height: 18)

            // 第二行：数值
            Text(value)
                .font(.glucoseMetric)
                .foregroundStyle(tintColor ?? .primary)
                .frame(height: 32, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppConstants.Spacing.md)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) \(value) \(subtitle ?? "")")
    }
}

#Preview("基础卡片 - 两行") {
    HStack {
        StatCardView(title: "今日记录", value: "4", subtitle: "次")
        StatCardView(title: "今日用药", value: "1", subtitle: "次")
    }
    .padding()
}

#Preview("带解释按钮 - 两行") {
    HStack {
        StatCardView(
            title: "今日均值",
            value: "5.2",
            tintColor: Color("GlucoseNormal"),
            metricType: .averageGlucose
        )
        StatCardView(
            title: "达标率",
            value: "85%",
            tintColor: Color("GlucoseNormal"),
            metricType: .timeInRange
        )
    }
    .padding()
}

#Preview("2x2 网格 - 两行结构") {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
        StatCardView(
            title: "今日记录",
            value: "7",
            subtitle: "次"
        )
        
        StatCardView(
            title: "今日均值",
            value: "5.2",
            tintColor: Color("GlucoseNormal"),
            metricType: .averageGlucose
        )
        
        StatCardView(
            title: "达标率",
            value: "85%",
            tintColor: Color("GlucoseNormal"),
            metricType: .timeInRange
        )
        
        StatCardView(
            title: "今日用药",
            value: "1",
            subtitle: "次"
        )
    }
    .padding()
}
