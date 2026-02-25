//
//  MonthlyReportView.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/17.
//

import SwiftUI
import SwiftData
import PDFKit

/// 月度总结报告预览页
struct MonthlyReportView: View {
    @Query(sort: \GlucoseRecord.timestamp, order: .reverse) private var allRecords: [GlucoseRecord]
    @Query(sort: \MedicationRecord.timestamp, order: .reverse) private var allMedications: [MedicationRecord]
    @Query private var settingsArray: [UserSettings]
    @State private var selectedMonth: Date = Date.now
    @State private var pdfData: Data?

    private var settings: UserSettings {
        settingsArray.first ?? UserSettings()
    }

    private var unit: GlucoseUnit {
        settings.preferredUnit
    }

    /// 可选月份列表（最近 12 个月）
    private var availableMonths: [Date] {
        let calendar = Calendar.current
        return (0..<12).compactMap { offset in
            calendar.date(byAdding: .month, value: -offset, to: Date.now)
        }
    }

    var body: some View {
        VStack(spacing: AppConstants.Spacing.lg) {
            monthPicker
                .padding(.horizontal, AppConstants.Spacing.lg)

            if let pdfData {
                PDFKitView(data: pdfData)
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))
                    .padding(.horizontal, AppConstants.Spacing.lg)
            } else {
                VStack {
                    Spacer()
                    ProgressView(String(localized: "monthly.generating"))
                    Spacer()
                }
            }

            if pdfData != nil {
                Button(action: sharePDF) {
                    Label(String(localized: "monthly.share_button"), systemImage: "square.and.arrow.up")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: AppConstants.Size.saveButtonHeight)
                        .background(Color("BrandPrimary"))
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.buttonLarge))
                }
                .padding(.horizontal, AppConstants.Spacing.lg)
                .padding(.bottom, AppConstants.Spacing.sm)
            }
        }
        .navigationTitle(String(localized: "monthly.title"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            generateReport()
        }
        .onChange(of: selectedMonth) {
            generateReport()
        }
    }

    // MARK: - 月份选择器

    private var monthPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppConstants.Spacing.sm) {
                ForEach(availableMonths, id: \.self) { month in
                    let isSelected = Calendar.current.isDate(month, equalTo: selectedMonth, toGranularity: .month)
                    Button {
                        selectedMonth = month
                    } label: {
                        Text(monthLabel(for: month))
                            .font(.caption.weight(isSelected ? .semibold : .regular))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule().fill(
                                    isSelected
                                        ? Color("BrandPrimary").opacity(0.15)
                                        : Color(.tertiarySystemGroupedBackground)
                                )
                            )
                            .foregroundStyle(
                                isSelected ? Color("BrandPrimary") : .secondary
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func monthLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"  // 使用通用格式
        return formatter.string(from: date)
    }

    // MARK: - 方法

    private func generateReport() {
        pdfData = PDFExportService.generateMonthlyReport(
            records: allRecords,
            medications: allMedications,
            settings: settings,
            month: selectedMonth,
            unit: unit
        )
    }

    private func sharePDF() {
        guard let pdfData else { return }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let monthStr = formatter.string(from: selectedMonth)
        
        let filenamePrefix = String(localized: "monthly.filename_prefix")
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(filenamePrefix)_\(monthStr).pdf")
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
        MonthlyReportView()
    }
    .modelContainer(for: [GlucoseRecord.self, UserSettings.self, MedicationRecord.self], inMemory: true)
}
