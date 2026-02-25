//
//  PDFExportService.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import UIKit
import PDFKit

/// 导出记录类型
enum ExportRecordType: String, CaseIterable, Identifiable {
    case all = "all"
    case glucoseOnly = "glucose"
    case medicationOnly = "medication"
    case mealOnly = "meal"
    
    var id: String { rawValue }
    
    var localizedName: String {
        switch self {
        case .all: return String(localized: "pdf.all_records")
        case .glucoseOnly: return String(localized: "pdf.glucose_only")
        case .medicationOnly: return String(localized: "pdf.medication_only")
        case .mealOnly: return String(localized: "pdf.meal_only")
        }
    }
}

/// PDF 报告生成服务
struct PDFExportService {

    /// 生成血糖报告 PDF（包含血糖、用药、饮食记录）
    /// - Parameters:
    ///   - records: 血糖记录列表
    ///   - dateRange: 日期范围描述
    ///   - unit: 显示单位
    ///   - settings: 用户设置(用于判断显示模式)
    ///   - medications: 用药记录列表
    ///   - meals: 饮食记录列表
    ///   - recordType: 导出记录类型
    /// - Returns: PDF 文件的 Data
    static func generateReport(
        records: [GlucoseRecord],
        dateRange: String,
        unit: GlucoseUnit,
        settings: UserSettings? = nil,
        medications: [MedicationRecord] = [],
        meals: [MealRecord] = [],
        recordType: ExportRecordType = .all
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
            
            // === 免责声明 ===
            let disclaimerText = String(localized: "pdf.disclaimer")
            let disclaimerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.systemRed
            ]
            disclaimerText.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: disclaimerAttributes)
            yOffset += 25

            // 1. 标题
            let title = String(localized: "pdf.report_title")
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.label
            ]
            title.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: titleAttributes)
            yOffset += 40

            // 2. 日期范围
            let subtitle = String(localized: "pdf.report_period", defaultValue: "报告周期：\(dateRange)")
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.secondaryLabel
            ]
            subtitle.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: subtitleAttributes)
            yOffset += 30

            // 3. 核心指标概览（扩展版，整合月度统计内容）
            if let avg = GlucoseCalculator.estimatedAverageGlucose(records: records) {
                let tir: Double
                let tar: Double
                let tbr: Double
                if let settings {
                    tir = GlucoseCalculator.contextualTimeInRange(records: records, settings: settings)
                    tar = GlucoseCalculator.contextualTimeAboveRange(records: records, settings: settings)
                    tbr = GlucoseCalculator.contextualTimeBelowRange(records: records, settings: settings)
                } else {
                    tir = GlucoseCalculator.timeInRange(records: records)
                    tar = GlucoseCalculator.timeAboveRange(records: records)
                    tbr = GlucoseCalculator.timeBelowRange(records: records)
                }
                
                let a1c = GlucoseCalculator.estimatedA1C(averageGlucoseMmolL: avg)
                let cv = GlucoseCalculator.coefficientOfVariation(records: records)
                
                let calendar = Calendar.current
                let daysWithRecords = Set(records.map { calendar.startOfDay(for: $0.timestamp) }).count
                let avgPerDay = daysWithRecords > 0 ? Double(records.count) / Double(daysWithRecords) : 0
                let medicationDays = Set(medications.map { calendar.startOfDay(for: $0.timestamp) }).count
                
                // 扩展指标显示
                let displayValue = GlucoseUnitConverter.displayString(mmolLValue: avg, in: unit)
                let summaryLines = [
                    String(localized: "pdf.record_count", defaultValue: "\(records.count) 次（\(daysWithRecords) 天有记录，日均 \(String(format: "%.1f", avgPerDay)) 次）"),
                    String(localized: "pdf.average_glucose", defaultValue: "平均血糖：\(displayValue) \(unit.rawValue)"),
                    String(localized: "pdf.estimated_a1c", defaultValue: "预估 A1C：\(String(format: "%.1f%%", a1c))"),
                    String(localized: "pdf.tir", defaultValue: "达标率 (TIR)：\(String(format: "%.1f%%", tir))（目标 > 70%）"),
                    String(localized: "pdf.tar", defaultValue: "高于范围 (TAR)：\(String(format: "%.1f%%", tar))（目标 < 25%）"),
                    String(localized: "pdf.tbr", defaultValue: "低于范围 (TBR)：\(String(format: "%.1f%%", tbr))（目标 < 4%）"),
                    cv != nil ? String(localized: "pdf.cv", defaultValue: "波动系数 (CV%)：\(String(format: "%.1f%%", cv!))（目标 < 36%）") : String(localized: "pdf.cv_insufficient"),
                    String(localized: "pdf.medication_days", defaultValue: "用药天数：\(medicationDays) 天")
                ]

                let summaryAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 11),
                    .foregroundColor: UIColor.label
                ]

                for line in summaryLines {
                    line.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: summaryAttributes)
                    yOffset += 18
                }
                yOffset += 12
            }

            // 4. 分隔线
            let lineRect = CGRect(x: margin, y: yOffset, width: contentWidth, height: 0.5)
            UIColor.separator.setFill()
            context.fill(lineRect)
            yOffset += 15
            
            // 5. 图表部分（如果数据足够）
            if let settings, records.count >= 10 {
                // 检查是否需要新页
                if yOffset > pageHeight - 400 {
                    drawDisclaimer(context: context, pageWidth: pageWidth, pageHeight: pageHeight, margin: margin)
                    context.beginPage()
                    yOffset = margin
                }
                
                let sectionAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
                    .foregroundColor: UIColor.label
                ]
                String(localized: "pdf.trend_chart").draw(at: CGPoint(x: margin, y: yOffset), withAttributes: sectionAttrs)
                yOffset += 20
                
                // 渲染 TAR/TIR/TBR 分布图
                if let rangeImage = ChartSnapshotService.renderRangeDistributionBar(
                    records: records,
                    settings: settings
                ) {
                    rangeImage.draw(in: CGRect(x: margin, y: yOffset, width: 250, height: 100))
                    yOffset += 110
                }
                
                // 渲染各场景 TIR 条形图
                if records.count >= 10, let tirChartImage = ChartSnapshotService.renderPerTagTIRChart(
                    records: records,
                    settings: settings
                ) {
                    tirChartImage.draw(in: CGRect(x: margin, y: yOffset, width: contentWidth, height: 180))
                    yOffset += 190
                }
                
                // 渲染箱线图
                if records.count >= 20, let boxPlotImage = ChartSnapshotService.renderBoxPlotChart(
                    records: records,
                    settings: settings
                ) {
                    boxPlotImage.draw(in: CGRect(x: margin, y: yOffset, width: contentWidth, height: 200))
                    yOffset += 210
                }
                
                yOffset += 12
                let lineRect2 = CGRect(x: margin, y: yOffset, width: contentWidth, height: 0.5)
                UIColor.separator.setFill()
                context.fill(lineRect2)
                yOffset += 15
            }

            // 6. 表头
            let headerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
                .foregroundColor: UIColor.label
            ]

            let headers = [
                String(localized: "pdf.table_header_date"),
                String(localized: "pdf.table_header_time"),
                String(localized: "pdf.table_header_type"),
                String(localized: "pdf.table_header_value"),
                String(localized: "pdf.table_header_scene"),
                String(localized: "pdf.table_header_note")
            ]
            let colWidths: [CGFloat] = [90, 55, 50, 100, 90, contentWidth - 385]
            var xOffset = margin

            for (i, header) in headers.enumerated() {
                header.draw(at: CGPoint(x: xOffset, y: yOffset), withAttributes: headerAttributes)
                xOffset += colWidths[i]
            }
            yOffset += 20

            // 7. 数据行 - 合并时间线（根据记录类型筛选）
            let rowAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.label
            ]

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            
            // 合并所有记录（根据 recordType 筛选）
            struct TimelineEntry: Comparable {
                let timestamp: Date
                let type: String
                let data: Any
                
                static func < (lhs: TimelineEntry, rhs: TimelineEntry) -> Bool {
                    lhs.timestamp > rhs.timestamp
                }
                
                static func == (lhs: TimelineEntry, rhs: TimelineEntry) -> Bool {
                    lhs.timestamp == rhs.timestamp && lhs.type == rhs.type
                }
            }
            
            var entries: [TimelineEntry] = []
            
            // 本地化的记录类型
            let typeGlucose = String(localized: "pdf.type_glucose")
            let typeMedication = String(localized: "pdf.type_medication")
            let typeMeal = String(localized: "pdf.type_meal")
            
            switch recordType {
            case .all:
                entries += records.map { TimelineEntry(timestamp: $0.timestamp, type: typeGlucose, data: $0) }
                entries += medications.map { TimelineEntry(timestamp: $0.timestamp, type: typeMedication, data: $0) }
                entries += meals.map { TimelineEntry(timestamp: $0.timestamp, type: typeMeal, data: $0) }
            case .glucoseOnly:
                entries = records.map { TimelineEntry(timestamp: $0.timestamp, type: typeGlucose, data: $0) }
            case .medicationOnly:
                entries = medications.map { TimelineEntry(timestamp: $0.timestamp, type: typeMedication, data: $0) }
            case .mealOnly:
                entries = meals.map { TimelineEntry(timestamp: $0.timestamp, type: typeMeal, data: $0) }
            }
            
            entries.sort()

            for entry in entries {
                // 检查是否需要新页
                if yOffset > pageHeight - 80 {
                    // 页脚免责声明
                    drawDisclaimer(context: context, pageWidth: pageWidth, pageHeight: pageHeight, margin: margin)
                    context.beginPage()
                    yOffset = margin
                }

                xOffset = margin
                let date = dateFormatter.string(from: entry.timestamp)
                let time = timeFormatter.string(from: entry.timestamp)
                
                var rowData: [String] = [date, time]
                
                if entry.type == typeGlucose {
                    if let record = entry.data as? GlucoseRecord {
                        // 计算阈值状态
                        let thresholdStatus: String
                        let thresholdRangeStr: String
                        if let settings {
                            let range = settings.thresholdRange(for: record.sceneTagId)
                            if record.value > range.high {
                                thresholdStatus = " ↑"
                            } else if record.value < range.low {
                                thresholdStatus = " ↓"
                            } else {
                                thresholdStatus = ""
                            }
                            thresholdRangeStr = " (\(String(format: "%.1f", range.low))-\(String(format: "%.1f", range.high)))"
                        } else {
                            thresholdStatus = ""
                            thresholdRangeStr = ""
                        }
                        
                        let value = "\(record.displayValue(in: unit))\(thresholdStatus) \(unit.rawValue)"
                        let context = settings?.displayName(for: record.sceneTagId) 
                            ?? MealContext(rawValue: record.sceneTagId)?.defaultDisplayName 
                            ?? String(localized: "pdf.other")
                        let contextWithRange = context + thresholdRangeStr
                        rowData += [typeGlucose, value, contextWithRange, record.note ?? ""]
                    }
                } else if entry.type == typeMedication {
                    if let medication = entry.data as? MedicationRecord {
                        let medType = medication.medicationType.displayName
                        let name = medication.name.isEmpty ? medType : medication.name
                        let dosage = medication.displayDosage
                        rowData += [typeMedication, name, dosage, medication.note ?? ""]
                    }
                } else if entry.type == typeMeal {
                    if let meal = entry.data as? MealRecord {
                        let description = meal.mealDescription.isEmpty ? String(localized: "pdf.meal_record") : meal.mealDescription
                        let carbLevel = meal.carbLevel.displayName
                        rowData += [typeMeal, description, carbLevel, meal.note ?? ""]
                    }
                }

                for (i, text) in rowData.enumerated() {
                    let rect = CGRect(x: xOffset, y: yOffset, width: colWidths[i] - 5, height: 16)
                    text.draw(in: rect, withAttributes: rowAttributes)
                    xOffset += colWidths[i]
                }
                yOffset += 18
            }

            // 8. 页脚免责声明
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
        let disclaimer = String(localized: "pdf.footer_disclaimer")
        let disclaimerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor.tertiaryLabel
        ]
        disclaimer.draw(
            in: CGRect(x: margin, y: pageHeight - 50, width: pageWidth - margin * 2, height: 30),
            withAttributes: disclaimerAttributes
        )
    }

    // MARK: - 月度总结报告

    /// 生成月度总结 PDF 报告
    static func generateMonthlyReport(
        records: [GlucoseRecord],
        medications: [MedicationRecord],
        settings: UserSettings,
        month: Date,
        unit: GlucoseUnit
    ) -> Data {
        let pageWidth: CGFloat = 595.2
        let pageHeight: CGFloat = 841.8
        let margin: CGFloat = 40.0
        let contentWidth = pageWidth - margin * 2

        let calendar = Calendar.current
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
        let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!
        let monthRecords = records.filter { $0.timestamp >= monthStart && $0.timestamp < monthEnd }
        let monthMedications = medications.filter { $0.timestamp >= monthStart && $0.timestamp < monthEnd }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"  // 使用通用格式
        let monthString = dateFormatter.string(from: month)

        let pdfRenderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        )

        return pdfRenderer.pdfData { context in
            context.beginPage()
            var yOffset: CGFloat = margin

            // -- 标题 --
            let title = String(localized: "pdf.monthly_title", defaultValue: "\(monthString) 血糖月度总结")
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 22, weight: .bold),
                .foregroundColor: UIColor.label
            ]
            title.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: titleAttrs)
            yOffset += 36

            let subtitleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.secondaryLabel
            ]
            let generatedDate = "生成日期：\(Date.now.fullDateTimeString)"
            generatedDate.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: subtitleAttrs)
            yOffset += 24

            // -- 分隔线 --
            drawLine(context: context, y: yOffset, x: margin, width: contentWidth)
            yOffset += 16

            // -- 核心指标概览 --
            let sectionAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 15, weight: .semibold),
                .foregroundColor: UIColor.label
            ]
            String(localized: "pdf.core_metrics").draw(at: CGPoint(x: margin, y: yOffset), withAttributes: sectionAttrs)
            yOffset += 24

            let metricAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.label
            ]
            let metricValueAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium),
                .foregroundColor: UIColor.label
            ]

            if let avg = GlucoseCalculator.estimatedAverageGlucose(records: monthRecords) {
                let tir = GlucoseCalculator.contextualTimeInRange(records: monthRecords, settings: settings)
                let tar = GlucoseCalculator.contextualTimeAboveRange(records: monthRecords, settings: settings)
                let tbr = GlucoseCalculator.contextualTimeBelowRange(records: monthRecords, settings: settings)
                let a1c = GlucoseCalculator.estimatedA1C(averageGlucoseMmolL: avg)
                let cv = GlucoseCalculator.coefficientOfVariation(records: monthRecords)

                let daysWithRecords = Set(monthRecords.map { calendar.startOfDay(for: $0.timestamp) }).count
                let avgPerDay = daysWithRecords > 0 ? Double(monthRecords.count) / Double(daysWithRecords) : 0

                let metrics: [(String, String)] = [
                    ("总记录次数", "\(monthRecords.count) 次（\(daysWithRecords) 天有记录，日均 \(String(format: "%.1f", avgPerDay)) 次）"),
                    ("平均血糖", "\(GlucoseUnitConverter.displayString(mmolLValue: avg, in: unit)) \(unit.rawValue)"),
                    ("预估 A1C", String(format: "%.1f%%", a1c)),
                    ("达标率 (TIR)", String(format: "%.1f%%（目标 > 70%%）", tir)),
                    ("高于范围 (TAR)", String(format: "%.1f%%（目标 < 25%%）", tar)),
                    ("低于范围 (TBR)", String(format: "%.1f%%（目标 < 4%%）", tbr)),
                    ("波动系数 (CV%)", cv != nil ? String(format: "%.1f%%（目标 < 36%%）", cv!) : "数据不足"),
                    ("用药天数", "\(Set(monthMedications.map { calendar.startOfDay(for: $0.timestamp) }).count) 天")
                ]

                for (label, value) in metrics {
                    label.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: metricAttrs)
                    value.draw(at: CGPoint(x: margin + 130, y: yOffset), withAttributes: metricValueAttrs)
                    yOffset += 18
                }
            } else {
                "本月暂无记录数据".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: metricAttrs)
                yOffset += 18
            }

            yOffset += 12
            drawLine(context: context, y: yOffset, x: margin, width: contentWidth)
            yOffset += 16
            
            // -- 图表部分 --
            if yOffset > pageHeight - 400 {
                drawDisclaimer(context: context, pageWidth: pageWidth, pageHeight: pageHeight, margin: margin)
                context.beginPage()
                yOffset = margin
            }
            
            "趋势图表".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: sectionAttrs)
            yOffset += 24
            
            // 渲染 TAR/TIR/TBR 分布图
            if let rangeImage = ChartSnapshotService.renderRangeDistributionBar(
                records: monthRecords,
                settings: settings
            ) {
                rangeImage.draw(in: CGRect(x: margin, y: yOffset, width: 250, height: 100))
                yOffset += 110
            }
            
            // 渲染各场景 TIR 条形图
            if monthRecords.count >= 10, let tirChartImage = ChartSnapshotService.renderPerTagTIRChart(
                records: monthRecords,
                settings: settings
            ) {
                tirChartImage.draw(in: CGRect(x: margin, y: yOffset, width: contentWidth, height: 180))
                yOffset += 190
            }
            
            // 渲染箱线图
            if monthRecords.count >= 20, let boxPlotImage = ChartSnapshotService.renderBoxPlotChart(
                records: monthRecords,
                settings: settings
            ) {
                boxPlotImage.draw(in: CGRect(x: margin, y: yOffset, width: contentWidth, height: 200))
                yOffset += 210
            }
            
            yOffset += 12
            drawLine(context: context, y: yOffset, x: margin, width: contentWidth)
            yOffset += 16

            // -- 各场景达标率 --
            "各场景达标率（按独立阈值）".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: sectionAttrs)
            yOffset += 24

            let headerAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
                .foregroundColor: UIColor.label
            ]
            let rowAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular),
                .foregroundColor: UIColor.label
            ]

            let tagHeaders = ["场景", "记录数", "平均值", "达标率", "阈值范围"]
            let tagColWidths: [CGFloat] = [70, 50, 70, 60, contentWidth - 250]
            var xOff = margin
            for (i, h) in tagHeaders.enumerated() {
                h.draw(at: CGPoint(x: xOff, y: yOffset), withAttributes: headerAttrs)
                xOff += tagColWidths[i]
            }
            yOffset += 18

            let byTag = Dictionary(grouping: monthRecords) { $0.sceneTagId }
            let sortedTags = byTag.sorted { $0.value.count > $1.value.count }

            for (tagId, tagRecords) in sortedTags {
                if yOffset > pageHeight - 80 {
                    drawDisclaimer(context: context, pageWidth: pageWidth, pageHeight: pageHeight, margin: margin)
                    context.beginPage()
                    yOffset = margin
                }

                let tagName = settings.displayName(for: tagId)
                let range = settings.thresholdRange(for: tagId)
                let avg = tagRecords.reduce(0.0) { $0 + $1.value } / Double(tagRecords.count)
                let inRange = tagRecords.filter { $0.value >= range.low && $0.value <= range.high }
                let tir = Double(inRange.count) / Double(tagRecords.count) * 100.0

                let rowData = [
                    tagName,
                    "\(tagRecords.count)",
                    "\(GlucoseUnitConverter.displayString(mmolLValue: avg, in: unit)) \(unit.rawValue)",
                    String(format: "%.0f%%", tir),
                    "\(String(format: "%.1f", range.low))–\(String(format: "%.1f", range.high))"
                ]

                xOff = margin
                for (i, text) in rowData.enumerated() {
                    text.draw(
                        in: CGRect(x: xOff, y: yOffset, width: tagColWidths[i] - 5, height: 16),
                        withAttributes: rowAttrs
                    )
                    xOff += tagColWidths[i]
                }
                yOffset += 16
            }

            yOffset += 12
            drawLine(context: context, y: yOffset, x: margin, width: contentWidth)
            yOffset += 16

            // -- 各场景血糖分布 --
            if yOffset > pageHeight - 160 {
                drawDisclaimer(context: context, pageWidth: pageWidth, pageHeight: pageHeight, margin: margin)
                context.beginPage()
                yOffset = margin
            }

            "各场景血糖分布".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: sectionAttrs)
            yOffset += 24

            let sceneHeaders = ["场景", "记录数", "中位数", "Q1–Q3 范围", "最低", "最高"]
            let sceneColWidths: [CGFloat] = [70, 50, 60, 100, 60, contentWidth - 340]
            xOff = margin
            for (i, h) in sceneHeaders.enumerated() {
                h.draw(at: CGPoint(x: xOff, y: yOffset), withAttributes: headerAttrs)
                xOff += sceneColWidths[i]
            }
            yOffset += 18

            let sceneByTag = Dictionary(grouping: monthRecords) { $0.sceneTagId }
            for (tagId, tagRecords) in sceneByTag {
                guard !tagRecords.isEmpty else { continue }

                let tagName = settings.displayName(for: tagId)
                let sorted = tagRecords.map(\.value).sorted()
                let count = sorted.count
                
                let median: Double
                let q1: Double
                let q3: Double
                
                if count == 1 {
                    // 只有 1 条记录，所有统计值相同
                    median = sorted[0]
                    q1 = sorted[0]
                    q3 = sorted[0]
                } else if count == 2 {
                    // 2 条记录，中位数为均值
                    median = (sorted[0] + sorted[1]) / 2.0
                    q1 = sorted[0]
                    q3 = sorted[1]
                } else if count == 3 {
                    // 3 条记录
                    median = sorted[1]
                    q1 = sorted[0]
                    q3 = sorted[2]
                } else {
                    // 4 条及以上，使用标准四分位数计算
                    median = count % 2 == 0
                        ? (sorted[count / 2 - 1] + sorted[count / 2]) / 2.0
                        : sorted[count / 2]
                    q1 = sorted[count / 4]
                    q3 = sorted[count * 3 / 4]
                }

                let rowData = [
                    tagName,
                    "\(count)",
                    String(format: "%.1f", median),
                    "\(String(format: "%.1f", q1))–\(String(format: "%.1f", q3))",
                    String(format: "%.1f", sorted.first ?? 0),
                    String(format: "%.1f", sorted.last ?? 0)
                ]

                xOff = margin
                for (i, text) in rowData.enumerated() {
                    text.draw(
                        in: CGRect(x: xOff, y: yOffset, width: sceneColWidths[i] - 5, height: 16),
                        withAttributes: rowAttrs
                    )
                    xOff += sceneColWidths[i]
                }
                yOffset += 16
            }

            yOffset += 12
            drawLine(context: context, y: yOffset, x: margin, width: contentWidth)
            yOffset += 16

            // -- 餐前餐后配对分析 --
            if yOffset > pageHeight - 120 {
                drawDisclaimer(context: context, pageWidth: pageWidth, pageHeight: pageHeight, margin: margin)
                context.beginPage()
                yOffset = margin
            }

            "餐前餐后配对分析".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: sectionAttrs)
            yOffset += 24

            let fastingRecords = monthRecords.filter { $0.thresholdGroup(from: settings) == .fasting }
            let postprandialRecords = monthRecords.filter { $0.thresholdGroup(from: settings) == .postprandial }

            var pairSpikes: [String: [Double]] = [:]
            for postRec in postprandialRecords {
                let sameDayFasting = fastingRecords.filter {
                    calendar.isDate($0.timestamp, inSameDayAs: postRec.timestamp)
                    && $0.timestamp < postRec.timestamp
                    && postRec.timestamp.timeIntervalSince($0.timestamp) <= 4 * 3600
                }
                if let closest = sameDayFasting.max(by: { $0.timestamp < $1.timestamp }) {
                    let spike = postRec.value - closest.value
                    let tagName = settings.displayName(for: postRec.sceneTagId)
                    pairSpikes[tagName, default: []].append(spike)
                }
            }

            if pairSpikes.isEmpty {
                "本月暂无可配对的餐前餐后数据".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: metricAttrs)
                yOffset += 18
            } else {
                let pairHeaders = ["餐次", "配对数", "平均升幅", "最大升幅", "超标次数(>3.0)"]
                let pairColWidths: [CGFloat] = [60, 50, 70, 70, contentWidth - 250]
                xOff = margin
                for (i, h) in pairHeaders.enumerated() {
                    h.draw(at: CGPoint(x: xOff, y: yOffset), withAttributes: headerAttrs)
                    xOff += pairColWidths[i]
                }
                yOffset += 18

                for (tagName, spikes) in pairSpikes.sorted(by: { $0.key < $1.key }) {
                    let avgSpike = spikes.reduce(0, +) / Double(spikes.count)
                    let maxSpike = spikes.max() ?? 0
                    let overCount = spikes.filter { $0 > 3.0 }.count

                    let rowData = [
                        tagName,
                        "\(spikes.count)",
                        String(format: "+%.1f", avgSpike),
                        String(format: "+%.1f", maxSpike),
                        "\(overCount) 次（\(String(format: "%.0f%%", Double(overCount) / Double(spikes.count) * 100))）"
                    ]

                    xOff = margin
                    for (i, text) in rowData.enumerated() {
                        text.draw(
                            in: CGRect(x: xOff, y: yOffset, width: pairColWidths[i] - 5, height: 16),
                            withAttributes: rowAttrs
                        )
                        xOff += pairColWidths[i]
                    }
                    yOffset += 16
                }
            }

            // 页脚
            drawDisclaimer(context: context, pageWidth: pageWidth, pageHeight: pageHeight, margin: margin)
        }
    }

    /// 绘制水平分隔线
    private static func drawLine(context: UIGraphicsPDFRendererContext, y: CGFloat, x: CGFloat, width: CGFloat) {
        let lineRect = CGRect(x: x, y: y, width: width, height: 0.5)
        UIColor.separator.setFill()
        context.fill(lineRect)
    }

    /// 生成 CSV 格式数据（包含血糖、用药、饮食记录）
    static func generateCSV(
        records: [GlucoseRecord],
        unit: GlucoseUnit,
        settings: UserSettings? = nil,
        medications: [MedicationRecord] = [],
        meals: [MealRecord] = [],
        recordType: ExportRecordType = .all
    ) -> String {
        var csv = "类型,日期,时间,血糖值,单位,阈值状态,阈值范围,场景,药物类型,药物名称,剂量,饮食描述,碳水等级,备注\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        // 合并所有记录并按时间排序（根据 recordType 筛选）
        struct TimelineEntry: Comparable {
            let timestamp: Date
            let type: String
            let data: Any
            
            static func < (lhs: TimelineEntry, rhs: TimelineEntry) -> Bool {
                lhs.timestamp > rhs.timestamp // 倒序
            }
            
            static func == (lhs: TimelineEntry, rhs: TimelineEntry) -> Bool {
                lhs.timestamp == rhs.timestamp && lhs.type == rhs.type
            }
        }
        
        var entries: [TimelineEntry] = []
        
        // 根据记录类型筛选
        switch recordType {
        case .all:
            entries += records.map { TimelineEntry(timestamp: $0.timestamp, type: "血糖", data: $0) }
            entries += medications.map { TimelineEntry(timestamp: $0.timestamp, type: "用药", data: $0) }
            entries += meals.map { TimelineEntry(timestamp: $0.timestamp, type: "饮食", data: $0) }
        case .glucoseOnly:
            entries = records.map { TimelineEntry(timestamp: $0.timestamp, type: "血糖", data: $0) }
        case .medicationOnly:
            entries = medications.map { TimelineEntry(timestamp: $0.timestamp, type: "用药", data: $0) }
        case .mealOnly:
            entries = meals.map { TimelineEntry(timestamp: $0.timestamp, type: "饮食", data: $0) }
        }
        
        // 排序
        entries.sort()
        
        for entry in entries {
            let date = dateFormatter.string(from: entry.timestamp)
            let time = timeFormatter.string(from: entry.timestamp)
            
            var row = "\(entry.type),\(date),\(time),"
            
            switch entry.type {
            case "血糖":
                if let record = entry.data as? GlucoseRecord {
                    let value = record.displayValue(in: unit)
                    
                    // 计算阈值状态和范围
                    let thresholdStatus: String
                    let thresholdRange: String
                    if let settings {
                        let range = settings.thresholdRange(for: record.sceneTagId)
                        if record.value > range.high {
                            thresholdStatus = "偏高 ↑"
                        } else if record.value < range.low {
                            thresholdStatus = "偏低 ↓"
                        } else {
                            thresholdStatus = "正常"
                        }
                        thresholdRange = "\(String(format: "%.1f", range.low))-\(String(format: "%.1f", range.high))"
                    } else {
                        thresholdStatus = ""
                        thresholdRange = ""
                    }
                    
                    let context = settings?.displayName(for: record.sceneTagId) 
                        ?? MealContext(rawValue: record.sceneTagId)?.defaultDisplayName 
                        ?? "其他"
                    let note = record.note?.replacingOccurrences(of: ",", with: "，") ?? ""
                    row += "\(value),\(unit.rawValue),\(thresholdStatus),\(thresholdRange),\(context),,,,,\(note)"
                }
                
            case "用药":
                if let medication = entry.data as? MedicationRecord {
                    let medType = medication.medicationType.displayName
                    let name = medication.name.isEmpty ? "-" : medication.name
                    let dosage = medication.displayDosage
                    let note = medication.note?.replacingOccurrences(of: ",", with: "，") ?? ""
                    row += ",,,,,,\(medType),\(name),\(dosage),,,\(note)"
                }
                
            case "饮食":
                if let meal = entry.data as? MealRecord {
                    let description = meal.mealDescription.isEmpty ? "-" : meal.mealDescription.replacingOccurrences(of: ",", with: "，")
                    let carbLevel = meal.carbLevel.displayName
                    let note = meal.note?.replacingOccurrences(of: ",", with: "，") ?? ""
                    row += ",,,,,,,,,\(description),\(carbLevel),\(note)"
                }
                
            default:
                break
            }
            
            csv += row + "\n"
        }

        return csv
    }
    
    // MARK: - 周报告
    
    /// 生成周报告 PDF
    static func generateWeeklyReport(
        records: [GlucoseRecord],
        medications: [MedicationRecord],
        meals: [MealRecord],
        settings: UserSettings,
        weekStart: Date,
        unit: GlucoseUnit
    ) -> Data {
        let pageWidth: CGFloat = 595.2
        let pageHeight: CGFloat = 841.8
        let margin: CGFloat = 40.0
        let contentWidth = pageWidth - margin * 2
        
        let calendar = Calendar.current
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
        
        // 上周数据用于对比（预留给未来的周对比功能）
        // let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: weekStart)!
        // let lastWeekEnd = weekStart
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "zh_CN")
        dateFormatter.dateFormat = "M月d日"
        let weekString = "\(dateFormatter.string(from: weekStart)) - \(dateFormatter.string(from: calendar.date(byAdding: .day, value: -1, to: weekEnd)!))"
        
        let pdfRenderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        )
        
        return pdfRenderer.pdfData { context in
            context.beginPage()
            var yOffset: CGFloat = margin
            
            // 标题
            let title = "周报告 - \(weekString)"
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 20, weight: .bold),
                .foregroundColor: UIColor.label
            ]
            title.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: titleAttrs)
            yOffset += 36
            
            let subtitleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.secondaryLabel
            ]
            let generatedDate = "生成日期：\(Date.now.fullDateTimeString)"
            generatedDate.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: subtitleAttrs)
            yOffset += 24
            
            drawLine(context: context, y: yOffset, x: margin, width: contentWidth)
            yOffset += 16
            
            // 本周概况
            let sectionAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 15, weight: .semibold),
                .foregroundColor: UIColor.label
            ]
            "本周概况".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: sectionAttrs)
            yOffset += 24
            
            let metricAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.label
            ]
            
            if let avg = GlucoseCalculator.estimatedAverageGlucose(records: records) {
                let tir = GlucoseCalculator.contextualTimeInRange(records: records, settings: settings)
                let cv = GlucoseCalculator.coefficientOfVariation(records: records)
                
                let daysWithRecords = Set(records.map { calendar.startOfDay(for: $0.timestamp) }).count
                let avgPerDay = daysWithRecords > 0 ? Double(records.count) / Double(daysWithRecords) : 0
                
                let medicationDays = Set(medications.map { calendar.startOfDay(for: $0.timestamp) }).count
                let mealDays = Set(meals.map { calendar.startOfDay(for: $0.timestamp) }).count
                
                let metrics: [(String, String)] = [
                    ("记录天数", "\(daysWithRecords) 天（日均 \(String(format: "%.1f", avgPerDay)) 次）"),
                    ("平均血糖", "\(GlucoseUnitConverter.displayString(mmolLValue: avg, in: unit)) \(unit.rawValue)"),
                    ("达标率 (TIR)", String(format: "%.1f%%", tir)),
                    ("波动系数 (CV%)", cv != nil ? String(format: "%.1f%%", cv!) : "数据不足"),
                    ("用药天数", "\(medicationDays) 天"),
                    ("饮食记录", "\(mealDays) 天")
                ]
                
                for (label, value) in metrics {
                    label.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: metricAttrs)
                    value.draw(at: CGPoint(x: margin + 120, y: yOffset), withAttributes: metricAttrs)
                    yOffset += 18
                }
            } else {
                "本周暂无记录数据".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: metricAttrs)
                yOffset += 18
            }
            
            yOffset += 12
            drawLine(context: context, y: yOffset, x: margin, width: contentWidth)
            yOffset += 16
            
            // 周对比（如果有上周数据）
            "本周 vs 上周对比".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: sectionAttrs)
            yOffset += 24
            
            // 这里需要传入所有记录以便筛选上周数据
            // 由于当前方法签名只传入本周数据，这里显示提示
            "需要完整历史数据进行对比分析".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: metricAttrs)
            yOffset += 24
            
            drawLine(context: context, y: yOffset, x: margin, width: contentWidth)
            yOffset += 16
            
            // 各场景达标率
            "各场景达标率".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: sectionAttrs)
            yOffset += 24
            
            let headerAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
                .foregroundColor: UIColor.label
            ]
            let rowAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular),
                .foregroundColor: UIColor.label
            ]
            
            let tagHeaders = ["场景", "记录数", "平均值", "达标率"]
            let tagColWidths: [CGFloat] = [80, 60, 90, contentWidth - 230]
            var xOff = margin
            for (i, h) in tagHeaders.enumerated() {
                h.draw(at: CGPoint(x: xOff, y: yOffset), withAttributes: headerAttrs)
                xOff += tagColWidths[i]
            }
            yOffset += 18
            
            let byTag = Dictionary(grouping: records) { $0.sceneTagId }
            for (tagId, tagRecords) in byTag.sorted(by: { $0.value.count > $1.value.count }) {
                let tagName = settings.displayName(for: tagId)
                let range = settings.thresholdRange(for: tagId)
                let avg = tagRecords.reduce(0.0) { $0 + $1.value } / Double(tagRecords.count)
                let inRange = tagRecords.filter { $0.value >= range.low && $0.value <= range.high }
                let tir = Double(inRange.count) / Double(tagRecords.count) * 100.0
                
                let rowData = [
                    tagName,
                    "\(tagRecords.count)",
                    "\(GlucoseUnitConverter.displayString(mmolLValue: avg, in: unit)) \(unit.rawValue)",
                    String(format: "%.0f%%", tir)
                ]
                
                xOff = margin
                for (i, text) in rowData.enumerated() {
                    text.draw(
                        in: CGRect(x: xOff, y: yOffset, width: tagColWidths[i] - 5, height: 16),
                        withAttributes: rowAttrs
                    )
                    xOff += tagColWidths[i]
                }
                yOffset += 16
            }
            
            // 页脚
            drawDisclaimer(context: context, pageWidth: pageWidth, pageHeight: pageHeight, margin: margin)
        }
    }
}
