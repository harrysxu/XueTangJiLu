//
//  GlucoseValueBadge.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import SwiftUI

/// 带颜色语义的血糖数值显示组件
struct GlucoseValueBadge: View {
    let value: Double
    let unit: GlucoseUnit
    let level: GlucoseLevel
    let style: BadgeStyle

    enum BadgeStyle {
        case hero      // 36pt，用于首页大数字
        case display   // 56pt，用于录入预览
        case callout   // 16pt，用于列表行
        case compact   // 14pt，用于 Widget

        var font: Font {
            switch self {
            case .hero:    return .glucoseHero
            case .display: return .glucoseDisplay
            case .callout: return .glucoseCallout
            case .compact: return .glucoseCompact
            }
        }

        var showUnit: Bool {
            switch self {
            case .hero, .display: return true
            case .callout, .compact: return false
            }
        }
    }

    private var formattedValue: String {
        GlucoseUnitConverter.displayString(mmolLValue: value, in: unit)
    }

    var body: some View {
        VStack(spacing: 2) {
            Text(formattedValue)
                .font(style.font)
                .foregroundStyle(Color.forGlucoseLevel(level))

            if style.showUnit {
                Text(unit.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("血糖 \(formattedValue) \(unit.rawValue)，\(level.description)")
    }
}

#Preview {
    VStack(spacing: 20) {
        GlucoseValueBadge(value: 5.6, unit: .mmolL, level: .normal, style: .hero)
        GlucoseValueBadge(value: 8.2, unit: .mmolL, level: .high, style: .display)
        GlucoseValueBadge(value: 3.5, unit: .mmolL, level: .low, style: .callout)
    }
}
