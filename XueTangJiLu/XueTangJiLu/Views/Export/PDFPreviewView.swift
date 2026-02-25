//
//  PDFPreviewView.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import SwiftUI
import SwiftData
import PDFKit

/// PDF 报告预览页
struct PDFPreviewView: View {
    @Query(sort: \GlucoseRecord.timestamp, order: .reverse) private var allRecords: [GlucoseRecord]
    @Query(sort: \MedicationRecord.timestamp, order: .reverse) private var allMedications: [MedicationRecord]
    @Query(sort: \MealRecord.timestamp, order: .reverse) private var allMeals: [MealRecord]
    @Query private var settingsArray: [UserSettings]
    @State private var settingsVM = SettingsViewModel()
    @State private var pdfData: Data?
    @State private var showShareSheet = false

    private var settings: UserSettings {
        settingsArray.first ?? UserSettings()
    }

    private var unit: GlucoseUnit {
        settings.preferredUnit
    }

    var body: some View {
        VStack(spacing: AppConstants.Spacing.lg) {
            // 日期范围选择
            dateRangeSection
                .padding(.horizontal, AppConstants.Spacing.lg)
            
            // 记录类型选择
            recordTypeSection
                .padding(.horizontal, AppConstants.Spacing.lg)

            // PDF 预览
            if let pdfData {
                PDFKitView(data: pdfData)
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))
                    .padding(.horizontal, AppConstants.Spacing.lg)
            } else {
                VStack {
                    Spacer()
                    ProgressView(String(localized: "generating_report"))
                    Spacer()
                }
            }

            // 分享按钮
            if pdfData != nil {
                Button(action: sharePDF) {
                    Label(String(localized: "pdf.share_report"), systemImage: "square.and.arrow.up")
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
        .navigationTitle(String(localized: "pdf.title"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            generatePDF()
        }
        .onChange(of: settingsVM.exportStartDate) {
            generatePDF()
        }
        .onChange(of: settingsVM.exportEndDate) {
            generatePDF()
        }
        .onChange(of: settingsVM.exportRecordType) {
            generatePDF()
        }
    }

    // MARK: - 日期范围

    private var dateRangeSection: some View {
        VStack(spacing: AppConstants.Spacing.sm) {
            DatePicker(
                String(localized: "pdf.start_date"),
                selection: $settingsVM.exportStartDate,
                in: ...settingsVM.exportEndDate,
                displayedComponents: .date
            )

            DatePicker(
                String(localized: "pdf.end_date"),
                selection: $settingsVM.exportEndDate,
                in: settingsVM.exportStartDate...Date.now,
                displayedComponents: .date
            )
        }
        .datePickerStyle(.compact)
        .padding(AppConstants.Spacing.lg)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))
    }
    
    // MARK: - 记录类型选择
    
    private var recordTypeSection: some View {
        VStack(spacing: AppConstants.Spacing.sm) {
            HStack {
                Text(String(localized: "pdf.record_type"))
                    .font(.subheadline.weight(.semibold))
                Spacer()
            }
            
            Picker(String(localized: "pdf.record_type"), selection: $settingsVM.exportRecordType) {
                ForEach(ExportRecordType.allCases) { type in
                    Text(type.localizedName).tag(type)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(AppConstants.Spacing.lg)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))
    }

    // MARK: - 方法

    private func generatePDF() {
        pdfData = settingsVM.generatePDF(
            records: allRecords, 
            unit: unit, 
            settings: settings,
            medications: allMedications,
            meals: allMeals
        )
    }

    private func sharePDF() {
        guard let pdfData else { return }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("血糖记录报告_\(settingsVM.exportDateRange).pdf")
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

/// UIViewRepresentable 包装 PDFKit 的 PDFView
struct PDFKitView: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = PDFDocument(data: data)
    }
}

#Preview {
    NavigationStack {
        PDFPreviewView()
    }
    .modelContainer(for: [GlucoseRecord.self, UserSettings.self, MedicationRecord.self, MealRecord.self], inMemory: true)
}
