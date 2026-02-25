//
//  SmallGlucoseWidget.swift
//  XueTangJiLuWidget
//
//  Created by XueTangJiLu on 2026/2/14.
//

import WidgetKit
import SwiftUI

/// 小号 Widget 视图：显示最新血糖读数 + 相对时间
struct SmallGlucoseWidgetView: View {
    let entry: GlucoseWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 血糖数值
            Text(entry.formattedValue)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(valueColor)
                .minimumScaleFactor(0.6)

            // 单位
            Text(entry.unit.rawValue)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Spacer()

            // 场景标签
            if let label = entry.sceneTagLabel {
                HStack(spacing: 2) {
                    Image(systemName: entry.sceneTagIcon ?? "clock")
                        .font(.caption2)
                    Text(label)
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }

            // 相对时间
            if let latestTime = entry.latestTime {
                Text(latestTime, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            } else {
                Text(String(localized: "empty.no_records"))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(4)
    }

    private var valueColor: Color {
        guard let level = entry.glucoseLevel else { return .secondary }
        return Color(level.colorName)
    }
}

