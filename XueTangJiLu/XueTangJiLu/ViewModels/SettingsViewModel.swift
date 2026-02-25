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
    
    /// 导出记录类型
    var exportRecordType: ExportRecordType = .all

    /// 导出日期范围字符串
    var exportDateRange: String {
        Date.rangeString(from: exportStartDate, to: exportEndDate)
    }

    /// 生成 PDF 数据
    func generatePDF(
        records: [GlucoseRecord], 
        unit: GlucoseUnit, 
        settings: UserSettings,
        medications: [MedicationRecord] = [],
        meals: [MealRecord] = []
    ) -> Data {
        let filteredRecords = records.filter {
            $0.timestamp >= exportStartDate && $0.timestamp <= exportEndDate
        }
        let filteredMedications = medications.filter {
            $0.timestamp >= exportStartDate && $0.timestamp <= exportEndDate
        }
        let filteredMeals = meals.filter {
            $0.timestamp >= exportStartDate && $0.timestamp <= exportEndDate
        }
        return PDFExportService.generateReport(
            records: filteredRecords,
            dateRange: exportDateRange,
            unit: unit,
            settings: settings,
            medications: filteredMedications,
            meals: filteredMeals,
            recordType: exportRecordType
        )
    }

    /// 生成 CSV 数据
    func generateCSV(
        records: [GlucoseRecord], 
        unit: GlucoseUnit, 
        settings: UserSettings,
        medications: [MedicationRecord] = [],
        meals: [MealRecord] = []
    ) -> String {
        let filteredRecords = records.filter {
            $0.timestamp >= exportStartDate && $0.timestamp <= exportEndDate
        }
        let filteredMedications = medications.filter {
            $0.timestamp >= exportStartDate && $0.timestamp <= exportEndDate
        }
        let filteredMeals = meals.filter {
            $0.timestamp >= exportStartDate && $0.timestamp <= exportEndDate
        }
        return PDFExportService.generateCSV(
            records: filteredRecords, 
            unit: unit, 
            settings: settings,
            medications: filteredMedications,
            meals: filteredMeals,
            recordType: exportRecordType
        )
    }
}
