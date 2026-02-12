//
//  Font+Theme.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import SwiftUI

extension Font {
    /// 录入页大数字预览 (56pt Rounded Bold)
    static let glucoseDisplay = Font.system(size: 56, weight: .bold, design: .rounded)
        .monospacedDigit()

    /// 首页最新读数 (36pt Rounded Bold)
    static let glucoseHero = Font.system(size: 36, weight: .bold, design: .rounded)
        .monospacedDigit()

    /// 统计指标数值 (18pt Rounded Medium)
    static let glucoseMetric = Font.system(size: 18, weight: .medium, design: .rounded)
        .monospacedDigit()

    /// 列表中的数值 (16pt Rounded Semibold)
    static let glucoseCallout = Font.system(size: 16, weight: .semibold, design: .rounded)
        .monospacedDigit()

    /// Widget 中的数值 (14pt Rounded Medium)
    static let glucoseCompact = Font.system(size: 14, weight: .medium, design: .rounded)
        .monospacedDigit()

    /// 键盘按键文字 (28pt Rounded Medium)
    static let keypadButton = Font.system(size: 28, weight: .medium, design: .rounded)
}
