//
//  CSVExportView.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/21.
//

import SwiftUI
import SwiftData

/// CSV 导出视图，支持日期范围选择
struct CSVExportView: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Query(sort: \GlucoseRecord.timestamp, order: .reverse) private var allRecords: [GlucoseRecord]
    @Query(sort: \MedicationRecord.timestamp, order: .reverse) private var allMedications: [MedicationRecord]
    @Query(sort: \MealRecord.timestamp, order: .reverse) private var allMeals: [MealRecord]
    @Query private var settingsArray: [UserSettings]
    @State private var settingsVM = SettingsViewModel()
    @State private var showShareSheet = false
    
    private var settings: UserSettings {
        settingsArray.first ?? UserSettings()
    }
    
    private var unit: GlucoseUnit {
        settings.preferredUnit
    }
    
    /// 筛选后的记录数量
    private var filteredCount: Int {
        let recordCount = allRecords.filter {
            $0.timestamp >= settingsVM.exportStartDate && $0.timestamp <= settingsVM.exportEndDate
        }.count
        let medicationCount = allMedications.filter {
            $0.timestamp >= settingsVM.exportStartDate && $0.timestamp <= settingsVM.exportEndDate
        }.count
        let mealCount = allMeals.filter {
            $0.timestamp >= settingsVM.exportStartDate && $0.timestamp <= settingsVM.exportEndDate
        }.count
        
        // 根据记录类型返回对应的计数
        switch settingsVM.exportRecordType {
        case .all:
            return recordCount + medicationCount + mealCount
        case .glucoseOnly:
            return recordCount
        case .medicationOnly:
            return medicationCount
        case .mealOnly:
            return mealCount
        }
    }
    
    var body: some View {
        Group {
            if !FeatureManager.canAccessFeature(.csvExport, isPremium: subscriptionManager.isPremiumUser) {
                ScrollView {
                    VStack {
                        Spacer()
                        FeatureLockView(feature: .csvExport)
                        Spacer()
                    }
                }
                .navigationTitle(String(localized: "csv.title"))
                .navigationBarTitleDisplayMode(.inline)
                .background(Color.pageBackground)
            } else {
                csvContentView
            }
        }
    }
    
    private var csvContentView: some View {
        ScrollView {
            VStack(spacing: AppConstants.Spacing.xl) {
                dateRangeSection
                recordTypeSection
                statsSection
                exportButton
            }
            .padding(.horizontal, AppConstants.Spacing.lg)
            .padding(.vertical, AppConstants.Spacing.lg)
        }
        .navigationTitle(String(localized: "csv.title"))
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.pageBackground)
    }
    
    // MARK: - 日期范围
    
    private var dateRangeSection: some View {
        VStack(spacing: AppConstants.Spacing.sm) {
            HStack {
                Text(String(localized: "csv.date_range_section"))
                    .font(.subheadline.weight(.semibold))
                Spacer()
            }
            
            VStack(spacing: AppConstants.Spacing.md) {
                DatePicker(
                    String(localized: "csv.start_date"),
                    selection: $settingsVM.exportStartDate,
                    in: ...settingsVM.exportEndDate,
                    displayedComponents: .date
                )
                
                DatePicker(
                    String(localized: "csv.end_date"),
                    selection: $settingsVM.exportEndDate,
                    in: settingsVM.exportStartDate...Date.now,
                    displayedComponents: .date
                )
            }
            .datePickerStyle(.compact)
        }
        .padding(AppConstants.Spacing.lg)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))
    }
    
    // MARK: - 记录类型选择
    
    private var recordTypeSection: some View {
        VStack(spacing: AppConstants.Spacing.sm) {
            HStack {
                Text(String(localized: "csv.record_type_section"))
                    .font(.subheadline.weight(.semibold))
                Spacer()
            }
            
            Picker(String(localized: "csv.record_type_label"), selection: $settingsVM.exportRecordType) {
                ForEach(ExportRecordType.allCases) { type in
                    Text(type.localizedName).tag(type)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(AppConstants.Spacing.lg)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))
    }
    
    // MARK: - 统计信息
    
    private var statsSection: some View {
        VStack(spacing: AppConstants.Spacing.sm) {
            HStack {
                Text(String(localized: "csv.summary_section"))
                    .font(.subheadline.weight(.semibold))
                Spacer()
            }
            
            VStack(spacing: AppConstants.Spacing.md) {
                statRow(label: String(localized: "csv.date_range_label"), value: settingsVM.exportDateRange)
                Divider()
                statRow(label: String(localized: "csv.record_count_label"), value: String(localized: "csv.records_format", defaultValue: "\(filteredCount) 条"))
                Divider()
                statRow(label: String(localized: "csv.export_format_label"), value: String(localized: "csv.export_format_value"))
            }
            .padding(AppConstants.Spacing.lg)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))
        }
    }
    
    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
        }
    }
    
    // MARK: - 导出按钮
    
    private var exportButton: some View {
        Button(action: exportCSV) {
            Label(String(localized: "csv.export_button"), systemImage: "tablecells")
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: AppConstants.Size.saveButtonHeight)
                .background(filteredCount > 0 ? Color.brandPrimary : Color.gray)
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.buttonLarge))
        }
        .disabled(filteredCount == 0)
    }
    
    // MARK: - 方法
    
    private func exportCSV() {
        let csv = settingsVM.generateCSV(
            records: allRecords, 
            unit: unit, 
            settings: settings,
            medications: allMedications,
            meals: allMeals
        )
        let data = csv.data(using: .utf8) ?? Data()
        
        let filenamePrefix = String(localized: "csv.filename_prefix")
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(filenamePrefix)_\(settingsVM.exportDateRange).csv")
        try? data.write(to: tempURL)
        
        let activityVC = UIActivityViewController(
            activityItems: [tempURL],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

#Preview {
    NavigationStack {
        CSVExportView()
    }
    .modelContainer(for: [GlucoseRecord.self, UserSettings.self, MedicationRecord.self, MealRecord.self], inMemory: true)
    .environment(SubscriptionManager())
}
