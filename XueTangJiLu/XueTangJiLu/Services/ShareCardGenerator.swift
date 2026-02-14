//
//  ShareCardGenerator.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/14.
//

import UIKit
import SwiftUI

/// 分享卡片生成器
struct ShareCardGenerator {

    /// 生成血糖摘要分享卡片图片
    /// - Parameters:
    ///   - records: 血糖记录
    ///   - unit: 显示单位
    ///   - period: 摘要周期描述（如"本周"）
    ///   - targetLow: 目标下限
    ///   - targetHigh: 目标上限
    /// - Returns: 生成的 UIImage
    static func generateSummaryCard(
        records: [GlucoseRecord],
        unit: GlucoseUnit,
        period: String,
        targetLow: Double,
        targetHigh: Double
    ) -> UIImage? {
        let width: CGFloat = 375
        let height: CGFloat = 480
        let size = CGSize(width: width, height: height)

        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let ctx = context.cgContext

            // 背景渐变
            let colors = [
                UIColor(red: 0.31, green: 0.275, blue: 0.898, alpha: 1.0).cgColor,
                UIColor(red: 0.549, green: 0.333, blue: 0.910, alpha: 1.0).cgColor
            ]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1])!
            ctx.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: width, y: height), options: [])

            // 白色内容卡片
            let cardRect = CGRect(x: 20, y: 20, width: width - 40, height: height - 40)
            let cardPath = UIBezierPath(roundedRect: cardRect, cornerRadius: 20)
            UIColor.white.setFill()
            cardPath.fill()

            let margin: CGFloat = 40
            var yOffset: CGFloat = 40

            // App 名称
            let appName = "学糖记录"
            let appAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                .foregroundColor: UIColor(red: 0.31, green: 0.275, blue: 0.898, alpha: 1.0)
            ]
            appName.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: appAttrs)
            yOffset += 30

            // 周期标题
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 22, weight: .bold),
                .foregroundColor: UIColor.label
            ]
            "\(period)血糖摘要".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: titleAttrs)
            yOffset += 40

            // 统计数据
            let metricAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13),
                .foregroundColor: UIColor.secondaryLabel
            ]
            let valueAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 28, weight: .bold),
                .foregroundColor: UIColor.label
            ]

            let avg = GlucoseCalculator.estimatedAverageGlucose(records: records)
            let tir = GlucoseCalculator.timeInRange(records: records, low: targetLow, high: targetHigh)
            let cv = GlucoseCalculator.coefficientOfVariation(records: records)
            let a1c = avg.map { GlucoseCalculator.estimatedA1C(averageGlucoseMmolL: $0) }

            let metrics: [(String, String)] = [
                ("平均血糖", avg.map { GlucoseUnitConverter.displayString(mmolLValue: $0, in: unit) + " " + unit.rawValue } ?? "--"),
                ("记录次数", "\(records.count) 次"),
                ("达标率 (TIR)", String(format: "%.0f%%", tir)),
                ("预估 A1C", a1c.map { String(format: "%.1f%%", $0) } ?? "--"),
                ("波动系数 (CV%)", cv.map { String(format: "%.1f%%", $0) } ?? "--"),
            ]

            for (label, value) in metrics {
                label.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: metricAttrs)
                yOffset += 20
                value.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: valueAttrs)
                yOffset += 45
            }

            // 底部 disclaimer
            let disclaimer = "本数据仅供参考，不构成医疗建议"
            let disclaimerAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.tertiaryLabel
            ]
            disclaimer.draw(at: CGPoint(x: margin, y: height - 65), withAttributes: disclaimerAttrs)
        }
    }
}
