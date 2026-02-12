//
//  Color+Theme.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import SwiftUI

extension Color {
    // MARK: - 血糖语义色
    static let glucoseNormal = Color("GlucoseNormal")
    static let glucoseHigh = Color("GlucoseHigh")
    static let glucoseLow = Color("GlucoseLow")
    static let brandPrimary = Color("BrandPrimary")

    /// 根据血糖水平获取对应颜色
    static func forGlucoseLevel(_ level: GlucoseLevel) -> Color {
        switch level {
        case .normal:            return .glucoseNormal
        case .high:              return .glucoseHigh
        case .low, .veryHigh:    return .glucoseLow
        }
    }

    /// 根据血糖值直接获取对应颜色 (mmol/L)
    static func forGlucoseValue(_ value: Double) -> Color {
        forGlucoseLevel(GlucoseLevel.from(value: value))
    }
}
