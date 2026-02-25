//
//  WeeklyReportView.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/21.
//

import SwiftUI
import SwiftData
import PDFKit

/// 周报告视图
struct WeeklyReportView: View {
    @Query(sort: \GlucoseRecord.timestamp, order: .reverse) private var allRecords: [GlucoseRecord]
    @Query(sort: \MedicationRecord.timestamp, order: .reverse) private var allMedications: [MedicationRecord]
    @Query(sort: \MealRecord.timestamp, order: .reverse) private var allMeals: [MealRecord]
    @Query private var settingsArray: [UserSettings]
    
    @State private var selectedWeek: Date = Date.now
    @State private var pdfData: Data?
    @State private var showShareSheet = false
    
    private var settings: UserSettings {
        settingsArray.first ?? UserSettings()
    }
    
    private var unit: GlucoseUnit {
        settings.preferredUnit
    }
    
    /// 最近 12 周的选项
    private var recentWeeks: [Date] {
        (0..<12).compactMap { weekOffset in
            Calendar.current.date(byAdding: .weekOfYear, value: -weekOffset, to: Date.now)
        }
    }
    
    /// 格式化周描述
    private func weekString(for date: Date) -> String {
        let calendar = Calendar.current
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        
        let year = calendar.component(.year, from: weekStart)
        return "\(year)年 \(formatter.string(from: weekStart)) - \(formatter.string(from: weekEnd))"
    }
    
    var body: some View {
        VStack(spacing: AppConstants.Spacing.lg) {
            // 周选择
            weekSelectionSection
                .padding(.horizontal, AppConstants.Spacing.lg)
            
            // PDF 预览
            if let pdfData {
                PDFKitView(data: pdfData)
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))
                    .padding(.horizontal, AppConstants.Spacing.lg)
            } else {
                VStack {
                    Spacer()
                    ProgressView("生成周报告中...")
                    Spacer()
                }
            }
            
            // 分享按钮
            if pdfData != nil {
                Button(action: sharePDF) {
                    Label("分享周报告", systemImage: "square.and.arrow.up")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: AppConstants.Size.saveButtonHeight)
                        .background(Color.brandPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.buttonLarge))
                }
                .padding(.horizontal, AppConstants.Spacing.lg)
                .padding(.bottom, AppConstants.Spacing.sm)
            }
        }
        .navigationTitle("周报告")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.pageBackground)
        .onAppear {
            generatePDF()
        }
        .onChange(of: selectedWeek) {
            generatePDF()
        }
    }
    
    // MARK: - 周选择
    
    private var weekSelectionSection: some View {
        VStack(spacing: AppConstants.Spacing.sm) {
            HStack {
                Text("选择周")
                    .font(.subheadline.weight(.semibold))
                Spacer()
            }
            
            Picker("周", selection: $selectedWeek) {
                ForEach(recentWeeks, id: \.self) { week in
                    Text(weekString(for: week)).tag(week)
                }
            }
            .pickerStyle(.menu)
        }
        .padding(AppConstants.Spacing.lg)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))
    }
    
    // MARK: - 方法
    
    private func generatePDF() {
        let calendar = Calendar.current
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedWeek))!
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
        
        let weekRecords = allRecords.filter { $0.timestamp >= weekStart && $0.timestamp < weekEnd }
        let weekMedications = allMedications.filter { $0.timestamp >= weekStart && $0.timestamp < weekEnd }
        let weekMeals = allMeals.filter { $0.timestamp >= weekStart && $0.timestamp < weekEnd }
        
        pdfData = PDFExportService.generateWeeklyReport(
            records: weekRecords,
            medications: weekMedications,
            meals: weekMeals,
            settings: settings,
            weekStart: weekStart,
            unit: unit
        )
    }
    
    private func sharePDF() {
        guard let pdfData else { return }
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("周报告_\(weekString(for: selectedWeek)).pdf")
        try? pdfData.write(to: tempURL)
        
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
        WeeklyReportView()
    }
    .modelContainer(for: [GlucoseRecord.self, UserSettings.self, MedicationRecord.self, MealRecord.self], inMemory: true)
}
