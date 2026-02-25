//
//  ShareCardView.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/14.
//

import SwiftUI
import SwiftData

/// 分享卡片视图
struct ShareCardView: View {
    @Query(sort: \GlucoseRecord.timestamp, order: .reverse) private var allRecords: [GlucoseRecord]
    @Query private var settingsArray: [UserSettings]
    @State private var selectedPeriod: SharePeriod = .week
    @State private var generatedImage: UIImage?

    enum SharePeriod: String, CaseIterable {
        case week = "week"
        case month = "month"
        
        var localizedName: String {
            switch self {
            case .week: return String(localized: "share.week")
            case .month: return String(localized: "share.month")
            }
        }

        var days: Int {
            switch self {
            case .week:  return 7
            case .month: return 30
            }
        }
    }

    private var settings: UserSettings {
        settingsArray.first ?? UserSettings()
    }

    private var filteredRecords: [GlucoseRecord] {
        let startDate = Date.daysAgo(selectedPeriod.days)
        return allRecords.filter { $0.timestamp >= startDate }
    }

    var body: some View {
        VStack(spacing: AppConstants.Spacing.xl) {
            // 周期选择
            Picker(String(localized: "share.period_label"), selection: $selectedPeriod) {
                ForEach(SharePeriod.allCases, id: \.self) { period in
                    Text(period.localizedName).tag(period)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, AppConstants.Spacing.lg)

            // 预览
            if let image = generatedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                    .padding(.horizontal, AppConstants.Spacing.xl)
            } else {
                ProgressView()
                    .frame(height: 300)
            }

            // 分享按钮
            Button(action: shareCard) {
                Label(String(localized: "share.share_button"), systemImage: "square.and.arrow.up")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: AppConstants.Size.saveButtonHeight)
                    .background(Color.brandPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.buttonLarge))
            }
            .padding(.horizontal, AppConstants.Spacing.lg)
            .disabled(generatedImage == nil)

            Spacer()
        }
        .padding(.top, AppConstants.Spacing.lg)
        .navigationTitle(String(localized: "share.title"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { generateCard() }
        .onChange(of: selectedPeriod) { _, _ in generateCard() }
    }

    private func generateCard() {
        generatedImage = ShareCardGenerator.generateSummaryCard(
            records: filteredRecords,
            unit: settings.preferredUnit,
            period: selectedPeriod.localizedName,
            settings: settings
        )
    }

    private func shareCard() {
        guard let image = generatedImage else { return }
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

#Preview {
    NavigationStack {
        ShareCardView()
            .modelContainer(for: [GlucoseRecord.self, UserSettings.self], inMemory: true)
    }
}
