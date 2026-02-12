//
//  SettingsView.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import SwiftUI
import SwiftData

/// 设置页
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(HealthKitManager.self) private var healthKitManager
    @Query private var settingsArray: [UserSettings]
    @Query(sort: \GlucoseRecord.timestamp, order: .reverse) private var allRecords: [GlucoseRecord]
    @State private var showExportPDF = false
    @State private var showExportCSV = false

    private var settings: UserSettings {
        if let existing = settingsArray.first {
            return existing
        }
        let newSettings = UserSettings()
        modelContext.insert(newSettings)
        return newSettings
    }

    var body: some View {
        NavigationStack {
            Form {
                // 血糖偏好
                glucosePreferencesSection

                // 数据同步
                dataSyncSection

                // 数据管理
                dataManagementSection

                // 关于
                aboutSection
            }
            .navigationTitle("设置")
        }
    }

    // MARK: - 血糖偏好

    private var glucosePreferencesSection: some View {
        Section("血糖偏好") {
            // 单位选择
            NavigationLink {
                UnitPickerView()
            } label: {
                HStack {
                    Text("单位")
                    Spacer()
                    Text(settings.preferredUnit.rawValue)
                        .foregroundStyle(.secondary)
                }
            }

            // 目标下限
            HStack {
                Text("目标下限")
                Spacer()
                Text(targetLowDisplay)
                    .foregroundStyle(.secondary)
                Stepper("", value: Binding(
                    get: { settings.targetLow },
                    set: { settings.targetLow = $0 }
                ), in: 2.0...6.0, step: 0.1)
                .labelsHidden()
            }

            // 目标上限
            HStack {
                Text("目标上限")
                Spacer()
                Text(targetHighDisplay)
                    .foregroundStyle(.secondary)
                Stepper("", value: Binding(
                    get: { settings.targetHigh },
                    set: { settings.targetHigh = $0 }
                ), in: 5.0...15.0, step: 0.1)
                .labelsHidden()
            }

            // 智能标签
            Toggle("智能标签", isOn: Binding(
                get: { settings.autoTagEnabled },
                set: { settings.autoTagEnabled = $0 }
            ))
        }
    }

    private var targetLowDisplay: String {
        GlucoseUnitConverter.displayString(mmolLValue: settings.targetLow, in: settings.preferredUnit)
    }

    private var targetHighDisplay: String {
        GlucoseUnitConverter.displayString(mmolLValue: settings.targetHigh, in: settings.preferredUnit)
    }

    // MARK: - 数据同步

    private var dataSyncSection: some View {
        Section("数据同步") {
            HStack {
                Label("Apple Health 同步", systemImage: "heart.fill")
                    .foregroundStyle(.primary)
                Spacer()
                if settings.healthKitSyncEnabled {
                    Text("已连接")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else {
                    Button("连接") {
                        Task {
                            try? await healthKitManager.requestAuthorization()
                            settings.healthKitSyncEnabled = healthKitManager.isAuthorized
                        }
                    }
                    .font(.caption)
                }
            }

            HStack {
                Label("iCloud 同步", systemImage: "icloud")
                Spacer()
                Text("自动")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - 数据管理

    private var dataManagementSection: some View {
        Section("数据管理") {
            NavigationLink {
                PDFPreviewView()
            } label: {
                Label("导出 PDF 报告", systemImage: "doc.richtext")
            }

            Button(action: exportCSV) {
                Label("导出 CSV 数据", systemImage: "tablecells")
            }
        }
    }

    private func exportCSV() {
        let viewModel = SettingsViewModel()
        let csv = viewModel.generateCSV(records: allRecords, unit: settings.preferredUnit)
        let data = csv.data(using: .utf8) ?? Data()

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("血糖记录_\(Date.now.shortDateString).csv")
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

    // MARK: - 关于

    private var aboutSection: some View {
        Section("关于") {
            HStack {
                Text("版本")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                    .foregroundStyle(.secondary)
            }

            NavigationLink {
                AboutView(type: .privacy)
            } label: {
                Text("隐私政策")
            }

            NavigationLink {
                AboutView(type: .disclaimer)
            } label: {
                Text("免责声明")
            }

            Button(action: requestReview) {
                Text("给我们评分")
            }
        }
    }

    private func requestReview() {
        guard let url = URL(string: "https://apps.apple.com/app/id_placeholder") else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [GlucoseRecord.self, UserSettings.self], inMemory: true)
        .environment(HealthKitManager())
}
