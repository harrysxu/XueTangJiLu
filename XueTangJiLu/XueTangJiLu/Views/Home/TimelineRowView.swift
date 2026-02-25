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
    var settings: UserSettings? = nil

    private var level: GlucoseLevel {
        if let settings {
            return record.glucoseLevel(with: settings)
        }
        return record.glucoseLevel
    }

    private var contextDisplayName: String {
        if let settings {
            return settings.displayName(for: record.sceneTagId)
        }
        return MealContext(rawValue: record.sceneTagId)?.defaultDisplayName ?? "其他"
    }

    private var contextIconName: String {
        if let settings {
            return settings.iconName(for: record.sceneTagId)
        }
        return MealContext(rawValue: record.sceneTagId)?.iconName ?? "clock"
    }

    var body: some View {
        HStack(spacing: AppConstants.Spacing.md) {
            // 左侧：时间 + 场景图标
            VStack(alignment: .leading, spacing: 2) {
                Text(record.timestamp, format: .dateTime.hour().minute())
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                HStack(spacing: AppConstants.Spacing.xs) {
                    Image(systemName: contextIconName)
                        .font(.caption2)
                    Text(contextDisplayName)
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
                level: level,
                style: .callout
            )
        }
        .padding(.vertical, AppConstants.Spacing.md)
        .padding(.horizontal, AppConstants.Spacing.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(record.timestamp.timeString) \(contextDisplayName) 血糖 \(record.displayValue(in: unit)) \(unit.rawValue) \(level.description)"
        )
        .accessibilityHint("轻点可编辑，右划可删除")
    }
}

#Preview {
    List {
        TimelineRowView(
            record: GlucoseRecord(value: 5.6, sceneTagId: MealContext.beforeBreakfast.rawValue),
            unit: .mmolL
        )
        TimelineRowView(
            record: GlucoseRecord(value: 7.8, sceneTagId: MealContext.afterLunch.rawValue, note: "吃了火锅"),
            unit: .mmolL
        )
        TimelineRowView(
            record: GlucoseRecord(value: 3.5, sceneTagId: MealContext.fasting.rawValue),
            unit: .mmolL
        )
    }
}
