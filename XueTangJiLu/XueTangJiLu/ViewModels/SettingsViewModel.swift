//
//  SettingsViewModel.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import Foundation
import Observation

/// 设置页业务逻辑
@Observable
final class SettingsViewModel {

    /// PDF 导出日期范围
    var exportStartDate: Date = Date.daysAgo(30)
    var exportEndDate: Date = .now

    /// 导出日期范围字符串
    var exportDateRange: String {
        Date.rangeString(from: exportStartDate, to: exportEndDate)
    }

    /// 生成 PDF 数据
    func generatePDF(records: [GlucoseRecord], unit: GlucoseUnit) -> Data {
        let filtered = records.filter {
            $0.timestamp >= exportStartDate && $0.timestamp <= exportEndDate
        }
        return PDFExportService.generateReport(
            records: filtered,
            dateRange: exportDateRange,
            unit: unit
        )
    }

    /// 生成 CSV 数据
    func generateCSV(records: [GlucoseRecord], unit: GlucoseUnit) -> String {
        let filtered = records.filter {
            $0.timestamp >= exportStartDate && $0.timestamp <= exportEndDate
        }
        return PDFExportService.generateCSV(records: filtered, unit: unit)
    }
}
