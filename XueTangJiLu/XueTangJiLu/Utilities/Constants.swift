//
//  Constants.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import Foundation
import SwiftUI

/// 全局常量定义
enum AppConstants {

    // MARK: - 血糖阈值 (mmol/L)

    /// 低血糖阈值
    static let glucoseLowThreshold: Double = 3.9
    /// 正常上限
    static let glucoseNormalUpperThreshold: Double = 7.0
    /// 偏高上限
    static let glucoseHighUpperThreshold: Double = 10.0

    // MARK: - 间距系统 (8pt grid)

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let section: CGFloat = 32
    }

    // MARK: - 圆角规范

    enum CornerRadius {
        static let fullCard: CGFloat = 20
        static let card: CGFloat = 16
        static let buttonLarge: CGFloat = 14
        static let buttonMedium: CGFloat = 12
        static let input: CGFloat = 10
    }

    // MARK: - 组件尺寸

    enum Size {
        /// 浮动录入按钮尺寸
        static let fabSize: CGFloat = 56
        /// 键盘按键高度
        static let keypadButtonHeight: CGFloat = 60
        /// 保存按钮高度
        static let saveButtonHeight: CGFloat = 54
        /// 场景标签高度
        static let tagHeight: CGFloat = 36
    }

    // MARK: - 单位转换

    /// mmol/L 与 mg/dL 之间的换算因子
    static let glucoseConversionFactor: Double = 18.0182

    // MARK: - CV% 阈值

    /// 波动系数稳定阈值（低于此值认为血糖波动稳定）
    static let cvStableThreshold: Double = 36.0

    // MARK: - TIR 目标

    /// TIR 达标率目标（>70% 为良好）
    static let tirGoodThreshold: Double = 70.0

    // MARK: - Widget 刷新

    /// Widget 刷新间隔（分钟）
    static let widgetRefreshInterval: Int = 30

    // MARK: - CloudKit

    static let cloudKitContainerID = "iCloud.com.xxl.XueTangJiLu"
    static let appGroupID = "group.com.xxl.XueTangJiLu"
}
