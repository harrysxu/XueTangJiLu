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

            // PDF 预览
            if let pdfData {
                PDFKitView(data: pdfData)
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))
                    .padding(.horizontal, AppConstants.Spacing.lg)
            } else {
                VStack {
                    Spacer()
                    ProgressView("生成报告中...")
                    Spacer()
                }
            }

            // 分享按钮
            if pdfData != nil {
                Button(action: sharePDF) {
                    Label("分享报告", systemImage: "square.and.arrow.up")
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
        .navigationTitle("PDF 报告")
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
    }

    // MARK: - 日期范围

    private var dateRangeSection: some View {
        VStack(spacing: AppConstants.Spacing.sm) {
            DatePicker(
                "开始日期",
                selection: $settingsVM.exportStartDate,
                in: ...settingsVM.exportEndDate,
                displayedComponents: .date
            )

            DatePicker(
                "结束日期",
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

    // MARK: - 方法

    private func generatePDF() {
        pdfData = settingsVM.generatePDF(records: allRecords, unit: unit)
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
    .modelContainer(for: [GlucoseRecord.self, UserSettings.self], inMemory: true)
}
