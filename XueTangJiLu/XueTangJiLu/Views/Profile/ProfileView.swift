//
//  ProfileView.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/14.
//

import SwiftUI
import SwiftData
import StoreKit

/// 我的 Tab - 设置 + 导出 + 成就 + 关于
struct ProfileView: View {
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

    /// 累计记录天数
    private var totalDays: Int {
        guard let earliest = allRecords.last?.timestamp else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: earliest, to: .now).day ?? 0
        return max(1, days)
    }

    /// 连续记录天数
    private var streakDays: Int {
        var streak = 0
        var currentDate = Calendar.current.startOfDay(for: .now)

        while true {
            let hasRecord = allRecords.contains { Calendar.current.isDate($0.timestamp, inSameDayAs: currentDate) }
            if hasRecord {
                streak += 1
                guard let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) else { break }
                currentDate = previousDay
            } else {
                break
            }
        }
        return streak
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppConstants.Spacing.xl) {
                    // 顶部概要
                    profileHeader

                    // 成就概览
                    achievementSection

                    // 偏好设置
                    preferencesSection

                    // 数据管理
                    dataManagementSection

                    // 关于
                    aboutSection
                }
                .padding(.horizontal, AppConstants.Spacing.lg)
                .padding(.vertical, AppConstants.Spacing.lg)
            }
            .background(Color.pageBackground)
            .navigationTitle("我的")
        }
    }

    // MARK: - 个人概要

    private var profileHeader: some View {
        HStack(spacing: AppConstants.Spacing.lg) {
            // 头像
            Image(systemName: "person.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.brandPrimary.opacity(0.7))

            VStack(alignment: .leading, spacing: AppConstants.Spacing.xs) {
                Text("控糖达人")
                    .font(.title3.weight(.semibold))

                HStack(spacing: AppConstants.Spacing.lg) {
                    VStack(alignment: .leading) {
                        Text("\(allRecords.count)")
                            .font(.glucoseCallout)
                        Text("总记录")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading) {
                        Text("\(totalDays)")
                            .font(.glucoseCallout)
                        Text("天")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading) {
                        Text("\(streakDays)")
                            .font(.glucoseCallout)
                            .foregroundStyle(Color("GlucoseNormal"))
                        Text("连续")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding(AppConstants.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.CornerRadius.fullCard)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        )
    }

    // MARK: - 成就概览

    private var achievementSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
            Text("成就徽章")
                .font(.subheadline.weight(.semibold))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppConstants.Spacing.md) {
                    achievementBadge(
                        icon: "flame.fill",
                        title: "连续记录",
                        subtitle: "\(streakDays) 天",
                        isAchieved: streakDays >= 3,
                        color: .orange
                    )

                    achievementBadge(
                        icon: "star.fill",
                        title: "初次记录",
                        subtitle: "完成",
                        isAchieved: !allRecords.isEmpty,
                        color: .yellow
                    )

                    achievementBadge(
                        icon: "chart.bar.fill",
                        title: "百次记录",
                        subtitle: "\(allRecords.count)/100",
                        isAchieved: allRecords.count >= 100,
                        color: Color.brandPrimary
                    )

                    achievementBadge(
                        icon: "target",
                        title: "TIR达标",
                        subtitle: "> 70%",
                        isAchieved: {
                            let week = allRecords.filter { $0.timestamp >= Date.daysAgo(7) }
                            guard !week.isEmpty else { return false }
                            let tir = GlucoseCalculator.timeInRange(records: week, low: settings.targetLow, high: settings.targetHigh)
                            return tir >= 70
                        }(),
                        color: Color("GlucoseNormal")
                    )
                }
            }
        }
    }

    private func achievementBadge(icon: String, title: String, subtitle: String, isAchieved: Bool, color: Color) -> some View {
        VStack(spacing: AppConstants.Spacing.sm) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(isAchieved ? color : Color(.systemGray4))
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(isAchieved ? color.opacity(0.12) : Color(.systemGray6))
                )

            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(isAchieved ? .primary : .secondary)

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(width: 80)
    }

    // MARK: - 偏好设置

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
            Text("偏好设置")
                .font(.subheadline.weight(.semibold))

            VStack(spacing: 0) {
                settingsRow(icon: "scalemass", title: "血糖单位", detail: settings.preferredUnit.rawValue) {
                    UnitPickerView()
                }

                Divider().padding(.leading, 52)

                settingsRow(icon: "target", title: "目标范围", detail: "\(targetLowDisplay) - \(targetHighDisplay)") {
                    TargetRangeSettingsView()
                }

                Divider().padding(.leading, 52)

                settingsRow(icon: "bell.badge", title: "提醒设置", detail: reminderSummary) {
                    ReminderSettingsView()
                }

                Divider().padding(.leading, 52)

                HStack(spacing: AppConstants.Spacing.md) {
                    Image(systemName: "wand.and.stars")
                        .font(.body)
                        .foregroundStyle(Color.brandPrimary)
                        .frame(width: 28)
                    Text("智能标签")
                        .font(.subheadline)
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { settings.autoTagEnabled },
                        set: { settings.autoTagEnabled = $0 }
                    ))
                }
                .padding(.horizontal, AppConstants.Spacing.lg)
                .padding(.vertical, AppConstants.Spacing.md)
            }
            .background(
                RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card)
                    .fill(Color.cardBackground)
            )
        }
    }

    private func settingsRow<Destination: View>(icon: String, title: String, detail: String, @ViewBuilder destination: () -> Destination) -> some View {
        NavigationLink(destination: destination) {
            HStack(spacing: AppConstants.Spacing.md) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(Color.brandPrimary)
                    .frame(width: 28)
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                Spacer()
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, AppConstants.Spacing.lg)
            .padding(.vertical, AppConstants.Spacing.md)
        }
        .buttonStyle(.plain)
    }

    private var targetLowDisplay: String {
        GlucoseUnitConverter.displayString(mmolLValue: settings.targetLow, in: settings.preferredUnit)
    }

    private var targetHighDisplay: String {
        GlucoseUnitConverter.displayString(mmolLValue: settings.targetHigh, in: settings.preferredUnit)
    }

    private var reminderSummary: String {
        let enabledCount = settings.reminderConfigs.filter(\.isEnabled).count
        return enabledCount > 0 ? "\(enabledCount) 个提醒" : "未设置"
    }

    // MARK: - 数据管理

    private var dataManagementSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
            Text("数据管理")
                .font(.subheadline.weight(.semibold))

            VStack(spacing: 0) {
                // HealthKit
                HStack(spacing: AppConstants.Spacing.md) {
                    Image(systemName: "heart.fill")
                        .font(.body)
                        .foregroundStyle(.red)
                        .frame(width: 28)
                    Text("Apple Health")
                        .font(.subheadline)
                    Spacer()
                    if settings.healthKitSyncEnabled {
                        Text("已连接")
                            .font(.caption)
                            .foregroundStyle(Color("GlucoseNormal"))
                    } else {
                        Button("连接") {
                            Task {
                                try? await healthKitManager.requestAuthorization()
                                settings.healthKitSyncEnabled = healthKitManager.isAuthorized
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(Color.brandPrimary)
                    }
                }
                .padding(.horizontal, AppConstants.Spacing.lg)
                .padding(.vertical, AppConstants.Spacing.md)

                Divider().padding(.leading, 52)

                // iCloud
                HStack(spacing: AppConstants.Spacing.md) {
                    Image(systemName: "icloud")
                        .font(.body)
                        .foregroundStyle(Color.brandPrimary)
                        .frame(width: 28)
                    Text("iCloud 同步")
                        .font(.subheadline)
                    Spacer()
                    Text("自动")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, AppConstants.Spacing.lg)
                .padding(.vertical, AppConstants.Spacing.md)

                Divider().padding(.leading, 52)

                // 导出
                NavigationLink(destination: PDFPreviewView()) {
                    HStack(spacing: AppConstants.Spacing.md) {
                        Image(systemName: "doc.richtext")
                            .font(.body)
                            .foregroundStyle(Color.brandPrimary)
                            .frame(width: 28)
                        Text("导出 PDF 报告")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, AppConstants.Spacing.lg)
                    .padding(.vertical, AppConstants.Spacing.md)
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 52)

                Button(action: exportCSV) {
                    HStack(spacing: AppConstants.Spacing.md) {
                        Image(systemName: "tablecells")
                            .font(.body)
                            .foregroundStyle(Color.brandPrimary)
                            .frame(width: 28)
                        Text("导出 CSV 数据")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, AppConstants.Spacing.lg)
                    .padding(.vertical, AppConstants.Spacing.md)
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 52)

                NavigationLink(destination: ShareCardView()) {
                    HStack(spacing: AppConstants.Spacing.md) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.body)
                            .foregroundStyle(Color.brandPrimary)
                            .frame(width: 28)
                        Text("分享血糖摘要")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, AppConstants.Spacing.lg)
                    .padding(.vertical, AppConstants.Spacing.md)
                }
                .buttonStyle(.plain)
            }
            .background(
                RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card)
                    .fill(Color.cardBackground)
            )
        }
    }

    private func exportCSV() {
        let viewModel = SettingsViewModel()
        let csv = viewModel.generateCSV(records: allRecords, unit: settings.preferredUnit)
        let data = csv.data(using: .utf8) ?? Data()

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("血糖记录_\(Date.now.shortDateString).csv")
        try? data.write(to: tempURL)

        let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }

    // MARK: - 关于

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
            Text("关于")
                .font(.subheadline.weight(.semibold))

            VStack(spacing: 0) {
                HStack(spacing: AppConstants.Spacing.md) {
                    Image(systemName: "info.circle")
                        .font(.body)
                        .foregroundStyle(Color.brandPrimary)
                        .frame(width: 28)
                    Text("版本")
                        .font(.subheadline)
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, AppConstants.Spacing.lg)
                .padding(.vertical, AppConstants.Spacing.md)

                Divider().padding(.leading, 52)

                NavigationLink(destination: AboutView(type: .privacy)) {
                    HStack(spacing: AppConstants.Spacing.md) {
                        Image(systemName: "hand.raised")
                            .font(.body)
                            .foregroundStyle(Color.brandPrimary)
                            .frame(width: 28)
                        Text("隐私政策")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, AppConstants.Spacing.lg)
                    .padding(.vertical, AppConstants.Spacing.md)
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 52)

                NavigationLink(destination: AboutView(type: .disclaimer)) {
                    HStack(spacing: AppConstants.Spacing.md) {
                        Image(systemName: "doc.text")
                            .font(.body)
                            .foregroundStyle(Color.brandPrimary)
                            .frame(width: 28)
                        Text("免责声明")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, AppConstants.Spacing.lg)
                    .padding(.vertical, AppConstants.Spacing.md)
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 52)

                Button(action: requestReview) {
                    HStack(spacing: AppConstants.Spacing.md) {
                        Image(systemName: "star")
                            .font(.body)
                            .foregroundStyle(.yellow)
                            .frame(width: 28)
                        Text("给我们评分")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, AppConstants.Spacing.lg)
                    .padding(.vertical, AppConstants.Spacing.md)
                }
                .buttonStyle(.plain)
            }
            .background(
                RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card)
                    .fill(Color.cardBackground)
            )
        }
    }

    private func requestReview() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            AppStore.requestReview(in: windowScene)
        }
    }
}

// MARK: - 目标范围设置子页

struct TargetRangeSettingsView: View {
    @Query private var settingsArray: [UserSettings]

    private var settings: UserSettings {
        settingsArray.first ?? UserSettings()
    }

    var body: some View {
        Form {
            Section("目标血糖范围") {
                HStack {
                    Text("目标下限")
                    Spacer()
                    Text(GlucoseUnitConverter.displayString(mmolLValue: settings.targetLow, in: settings.preferredUnit))
                        .foregroundStyle(.secondary)
                    Stepper("", value: Binding(
                        get: { settings.targetLow },
                        set: { settings.targetLow = $0 }
                    ), in: 2.0...6.0, step: 0.1)
                    .labelsHidden()
                }

                HStack {
                    Text("目标上限")
                    Spacer()
                    Text(GlucoseUnitConverter.displayString(mmolLValue: settings.targetHigh, in: settings.preferredUnit))
                        .foregroundStyle(.secondary)
                    Stepper("", value: Binding(
                        get: { settings.targetHigh },
                        set: { settings.targetHigh = $0 }
                    ), in: 5.0...15.0, step: 0.1)
                    .labelsHidden()
                }
            }

            Section("A1C 目标") {
                HStack {
                    Text("目标 A1C")
                    Spacer()
                    Text(String(format: "%.1f%%", settings.targetA1C))
                        .foregroundStyle(.secondary)
                    Stepper("", value: Binding(
                        get: { settings.targetA1C },
                        set: { settings.targetA1C = $0 }
                    ), in: 4.0...12.0, step: 0.1)
                    .labelsHidden()
                }
            }

            Section("每日记录目标") {
                HStack {
                    Text("目标次数")
                    Spacer()
                    Text("\(settings.dailyRecordGoal) 次")
                        .foregroundStyle(.secondary)
                    Stepper("", value: Binding(
                        get: { settings.dailyRecordGoal },
                        set: { settings.dailyRecordGoal = $0 }
                    ), in: 1...10)
                    .labelsHidden()
                }
            }
        }
        .navigationTitle("目标范围")
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [GlucoseRecord.self, UserSettings.self, MedicationRecord.self], inMemory: true)
        .environment(HealthKitManager())
}
