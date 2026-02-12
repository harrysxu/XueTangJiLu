//
//  TimelineRowView.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import SwiftUI

/// 时间轴列表行
struct TimelineRowView: View {
    let record: GlucoseRecord
    let unit: GlucoseUnit

    var body: some View {
        HStack(spacing: AppConstants.Spacing.md) {
            // 左侧：时间 + 场景图标
            VStack(alignment: .leading, spacing: 2) {
                Text(record.timestamp, format: .dateTime.hour().minute())
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                HStack(spacing: AppConstants.Spacing.xs) {
                    Image(systemName: record.mealContext.iconName)
                        .font(.caption2)
                    Text(record.mealContext.displayName)
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }

            Spacer()

            // 备注指示
            if record.note != nil {
                Image(systemName: "note.text")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            // 右侧：血糖数值
            GlucoseValueBadge(
                value: record.value,
                unit: unit,
                level: record.glucoseLevel,
                style: .callout
            )
        }
        .padding(.vertical, AppConstants.Spacing.sm)
        .padding(.horizontal, AppConstants.Spacing.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(record.timestamp.timeString) \(record.mealContext.displayName) 血糖 \(record.displayValue(in: unit)) \(unit.rawValue) \(record.glucoseLevel.description)"
        )
        .accessibilityHint("右划可删除")
    }
}

#Preview {
    List {
        TimelineRowView(
            record: GlucoseRecord(value: 5.6, mealContext: .beforeBreakfast),
            unit: .mmolL
        )
        TimelineRowView(
            record: GlucoseRecord(value: 7.8, mealContext: .afterLunch, note: "吃了火锅"),
            unit: .mmolL
        )
        TimelineRowView(
            record: GlucoseRecord(value: 3.5, mealContext: .fasting),
            unit: .mmolL
        )
    }
}
