//
//  Color+Theme.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import SwiftUI

extension Color {
    /// 根据血糖水平获取对应颜色（使用 Asset Catalog 中的命名颜色）
    static func forGlucoseLevel(_ level: GlucoseLevel) -> Color {
        Color(level.colorName)
    }

    /// 根据血糖值直接获取对应颜色 (mmol/L)
    static func forGlucoseValue(_ value: Double) -> Color {
        forGlucoseLevel(GlucoseLevel.from(value: value))
    }

    // MARK: - 品牌渐变

    /// 品牌主色渐变 (Indigo → Purple)
    static var brandGradient: LinearGradient {
        LinearGradient(
            colors: [Color("BrandPrimary"), Color("BrandGradientEnd")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// 血糖值背景渐变色（根据血糖水平）
    static func glucoseGradient(for level: GlucoseLevel) -> LinearGradient {
        let color = Color(level.colorName)
        return LinearGradient(
            colors: [color.opacity(0.15), color.opacity(0.05)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - 语义化颜色

    /// 卡片背景色（适配深色模式）
    static var cardBackground: Color {
        Color(.secondarySystemGroupedBackground)
    }

    /// 页面背景色
    static var pageBackground: Color {
        Color(.systemGroupedBackground)
    }

    /// 分隔线颜色
    static var subtleDivider: Color {
        Color(.separator).opacity(0.5)
    }
}
