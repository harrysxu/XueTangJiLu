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
    #if DEBUG
    @State private var showTestDataGenerator = false
    #endif

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
            .toolbar(.hidden, for: .navigationBar)
            #if DEBUG
            .sheet(isPresented: $showTestDataGenerator) {
                TestDataGeneratorView()
            }
            #endif
        }
    }

    // MARK: - 个人概要

    private var profileHeader: some View {
        HStack(spacing: AppConstants.Spacing.lg) {
            // 头像
            Image(systemName: "person.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.brandPrimary.opacity(0.7))
                #if DEBUG
                .onTapGesture(count: 3) {
                    showTestDataGenerator = true
                }
                #endif

            VStack(alignment: .leading, spacing: AppConstants.Spacing.xs) {
                Text(String(localized: "profile.nickname"))
                    .font(.title3.weight(.semibold))

                HStack(spacing: AppConstants.Spacing.lg) {
                    VStack(alignment: .leading) {
                        Text("\(allRecords.count)")
                            .font(.glucoseCallout)
                        Text(String(localized: "profile.total"))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading) {
                        Text("\(totalDays)")
                            .font(.glucoseCallout)
                        Text(String(localized: "profile.days"))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading) {
                        Text("\(streakDays)")
                            .font(.glucoseCallout)
                            .foregroundStyle(Color("GlucoseNormal"))
                        Text(String(localized: "profile.streak"))
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
            Text(String(localized: "profile.achievements"))
                .font(.subheadline.weight(.semibold))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppConstants.Spacing.md) {
                    achievementBadge(
                        icon: "flame.fill",
                        title: String(localized: "achievement.streak"),
                        subtitle: "\(streakDays) \(String(localized: "profile.days"))",
                        isAchieved: streakDays >= 3,
                        color: .orange
                    )

                    achievementBadge(
                        icon: "star.fill",
                        title: String(localized: "achievement.first"),
                        subtitle: String(localized: "achievement.completed"),
                        isAchieved: !allRecords.isEmpty,
                        color: .yellow
                    )

                    achievementBadge(
                        icon: "chart.bar.fill",
                        title: String(localized: "achievement.hundred"),
                        subtitle: "\(allRecords.count)/100",
                        isAchieved: allRecords.count >= 100,
                        color: Color.brandPrimary
                    )

                    achievementBadge(
                        icon: "target",
                        title: String(localized: "achievement.tir"),
                        subtitle: "> 70%",
                        isAchieved: {
                            let week = allRecords.filter { $0.timestamp >= Date.daysAgo(7) }
                            guard !week.isEmpty else { return false }
                            let tir = GlucoseCalculator.contextualTimeInRange(records: week, settings: settings)
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
            Text(String(localized: "profile.preferences"))
                .font(.subheadline.weight(.semibold))

            VStack(spacing: 0) {
                settingsRow(icon: "scalemass", title: String(localized: "profile.unit"), detail: settings.preferredUnit.rawValue) {
                    UnitPickerView()
                }

                Divider().padding(.leading, 52)

                settingsRow(icon: "bell.badge", title: String(localized: "profile.reminders"), detail: reminderSummary) {
                    ReminderSettingsView()
                }

                Divider().padding(.leading, 52)

                settingsRow(icon: "tag", title: String(localized: "profile.tag_management"), detail: tagManagementSummary) {
                    TagManagementView()
                }
            }
            .background(
                RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card)
                    .fill(Color.cardBackground)
            )
        }
    }

    private var tagManagementSummary: String {
        let visibleCount = settings.visibleSceneTags.count
        let annotationCount = settings.visibleAnnotationTags.count
        return String(format: String(localized: "profile.tag_summary"), visibleCount, annotationCount)
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

    private var reminderSummary: String {
        let enabledCount = settings.reminderConfigs.filter(\.isEnabled).count
        return enabledCount > 0 ? String(format: String(localized: "profile.reminders_count"), enabledCount) : String(localized: "reminder.not_set")
    }

    // MARK: - 数据管理

    private var dataManagementSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
            Text(String(localized: "profile.data"))
                .font(.subheadline.weight(.semibold))

            VStack(spacing: 0) {
                // HealthKit
                HStack(spacing: AppConstants.Spacing.md) {
                    Image(systemName: "heart.fill")
                        .font(.body)
                        .foregroundStyle(.red)
                        .frame(width: 28)
                    Text(String(localized: "profile.health"))
                        .font(.subheadline)
                    Spacer()
                    if settings.healthKitSyncEnabled {
                        Text(String(localized: "profile.connected"))
                            .font(.caption)
                            .foregroundStyle(Color("GlucoseNormal"))
                    } else {
                        Button(String(localized: "profile.connect")) {
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
                NavigationLink(destination: SyncSettingsView()) {
                    HStack(spacing: AppConstants.Spacing.md) {
                        Image(systemName: "icloud")
                            .font(.body)
                            .foregroundStyle(Color.brandPrimary)
                            .frame(width: 28)
                        Text(String(localized: "profile.icloud"))
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Spacer()
                        SyncStatusBadge()
                    }
                    .padding(.horizontal, AppConstants.Spacing.lg)
                    .padding(.vertical, AppConstants.Spacing.md)
                }

                Divider().padding(.leading, 52)

                // 导出
                NavigationLink(destination: PDFPreviewView()) {
                    HStack(spacing: AppConstants.Spacing.md) {
                        Image(systemName: "doc.richtext")
                            .font(.body)
                            .foregroundStyle(Color.brandPrimary)
                            .frame(width: 28)
                        Text(String(localized: "profile.export_pdf"))
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

                // 月度总结
                NavigationLink(destination: MonthlyReportView()) {
                    HStack(spacing: AppConstants.Spacing.md) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.body)
                            .foregroundStyle(Color.brandPrimary)
                            .frame(width: 28)
                        Text(String(localized: "profile.monthly_report"))
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

                // 导出 CSV
                NavigationLink(destination: CSVExportView()) {
                    HStack(spacing: AppConstants.Spacing.md) {
                        Image(systemName: "tablecells")
                            .font(.body)
                            .foregroundStyle(Color.brandPrimary)
                            .frame(width: 28)
                        Text(String(localized: "profile.export_csv"))
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

                NavigationLink(destination: ShareCardView()) {
                    HStack(spacing: AppConstants.Spacing.md) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.body)
                            .foregroundStyle(Color.brandPrimary)
                            .frame(width: 28)
                        Text(String(localized: "profile.share"))
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

    // MARK: - 关于

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
            Text(String(localized: "profile.about"))
                .font(.subheadline.weight(.semibold))

            VStack(spacing: 0) {
                HStack(spacing: AppConstants.Spacing.md) {
                    Image(systemName: "info.circle")
                        .font(.body)
                        .foregroundStyle(Color.brandPrimary)
                        .frame(width: 28)
                    Text(String(localized: "profile.version"))
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
                        Text(String(localized: "profile.privacy"))
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
                        Text(String(localized: "profile.disclaimer"))
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
                        Text(String(localized: "profile.rate"))
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

#Preview {
    ProfileView()
        .modelContainer(for: [GlucoseRecord.self, UserSettings.self, MedicationRecord.self], inMemory: true)
        .environment(HealthKitManager())
}
