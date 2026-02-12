//
//  PDFExportService.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import UIKit
import PDFKit

/// PDF 报告生成服务
struct PDFExportService {

    /// 生成血糖报告 PDF
    /// - Parameters:
    ///   - records: 血糖记录列表
    ///   - dateRange: 日期范围描述
    ///   - unit: 显示单位
    /// - Returns: PDF 文件的 Data
    static func generateReport(
        records: [GlucoseRecord],
        dateRange: String,
        unit: GlucoseUnit
    ) -> Data {
        let pageWidth: CGFloat = 595.2   // A4 宽度 (pt)
        let pageHeight: CGFloat = 841.8  // A4 高度 (pt)
        let margin: CGFloat = 40.0
        let contentWidth = pageWidth - margin * 2

        let pdfRenderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        )

        return pdfRenderer.pdfData { context in
            context.beginPage()
            var yOffset: CGFloat = margin

            // 1. 标题
            let title = "血糖记录报告"
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.label
            ]
            title.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: titleAttributes)
            yOffset += 40

            // 2. 日期范围
            let subtitle = "报告周期：\(dateRange)"
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.secondaryLabel
            ]
            subtitle.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: subtitleAttributes)
            yOffset += 30

            // 3. 统计概要
            if let avg = GlucoseCalculator.estimatedAverageGlucose(records: records) {
                let tir = GlucoseCalculator.timeInRange(records: records)
                let a1c = GlucoseCalculator.estimatedA1C(averageGlucoseMmolL: avg)

                let summaryLines = [
                    "记录次数：\(records.count)",
                    "平均血糖：\(GlucoseUnitConverter.displayString(mmolLValue: avg, in: unit)) \(unit.rawValue)",
                    "达标率 (TIR)：\(String(format: "%.1f%%", tir))",
                    "预估 A1C：\(String(format: "%.1f%%", a1c))"
                ]

                let summaryAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor.label
                ]

                for line in summaryLines {
                    line.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: summaryAttributes)
                    yOffset += 20
                }
                yOffset += 10
            }

            // 4. 分隔线
            let lineRect = CGRect(x: margin, y: yOffset, width: contentWidth, height: 0.5)
            UIColor.separator.setFill()
            context.fill(lineRect)
            yOffset += 15

            // 5. 表头
            let headerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
                .foregroundColor: UIColor.label
            ]

            let headers = ["日期", "时间", "血糖值", "场景", "备注"]
            let colWidths: [CGFloat] = [100, 60, 80, 70, contentWidth - 310]
            var xOffset = margin

            for (i, header) in headers.enumerated() {
                header.draw(at: CGPoint(x: xOffset, y: yOffset), withAttributes: headerAttributes)
                xOffset += colWidths[i]
            }
            yOffset += 20

            // 6. 数据行
            let rowAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.label
            ]

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"

            for record in records.sorted(by: { $0.timestamp > $1.timestamp }) {
                // 检查是否需要新页
                if yOffset > pageHeight - 80 {
                    // 页脚免责声明
                    drawDisclaimer(context: context, pageWidth: pageWidth, pageHeight: pageHeight, margin: margin)
                    context.beginPage()
                    yOffset = margin
                }

                xOffset = margin
                let rowData = [
                    dateFormatter.string(from: record.timestamp),
                    timeFormatter.string(from: record.timestamp),
                    "\(record.displayValue(in: unit)) \(unit.rawValue)",
                    record.mealContext.displayName,
                    record.note ?? ""
                ]

                for (i, text) in rowData.enumerated() {
                    let rect = CGRect(x: xOffset, y: yOffset, width: colWidths[i] - 5, height: 16)
                    text.draw(in: rect, withAttributes: rowAttributes)
                    xOffset += colWidths[i]
                }
                yOffset += 18
            }

            // 7. 页脚免责声明
            drawDisclaimer(context: context, pageWidth: pageWidth, pageHeight: pageHeight, margin: margin)
        }
    }

    /// 绘制页脚免责声明
    private static func drawDisclaimer(
        context: UIGraphicsPDFRendererContext,
        pageWidth: CGFloat,
        pageHeight: CGFloat,
        margin: CGFloat
    ) {
        let disclaimer = "免责声明：本报告仅用于信息记录，不作为医疗诊断依据。做出医疗决定前请咨询医生。"
        let disclaimerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor.tertiaryLabel
        ]
        disclaimer.draw(
            in: CGRect(x: margin, y: pageHeight - 50, width: pageWidth - margin * 2, height: 30),
            withAttributes: disclaimerAttributes
        )
    }

    /// 生成 CSV 格式数据
    static func generateCSV(
        records: [GlucoseRecord],
        unit: GlucoseUnit
    ) -> String {
        var csv = "日期,时间,血糖值(\(unit.rawValue)),场景,备注\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        for record in records.sorted(by: { $0.timestamp > $1.timestamp }) {
            let date = dateFormatter.string(from: record.timestamp)
            let time = timeFormatter.string(from: record.timestamp)
            let value = record.displayValue(in: unit)
            let context = record.mealContext.displayName
            let note = record.note?.replacingOccurrences(of: ",", with: "，") ?? ""
            csv += "\(date),\(time),\(value),\(context),\(note)\n"
        }

        return csv
    }
}
