//
//  SettingsView.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import SwiftUI
import SwiftData
import StoreKit

/// 设置页
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(HealthKitManager.self) private var healthKitManager
    @Environment(SubscriptionManager.self) private var subscriptionManager
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
                // 订阅状态
                subscriptionSection
                
                // 显示偏好
                displayPreferencesSection
                
                // 血糖偏好
                glucosePreferencesSection

                // 数据同步
                dataSyncSection

                // 数据管理
                dataManagementSection

                // 关于
                aboutSection
            }
            .navigationTitle(String(localized: "settings.title"))
        }
    }
    
    // MARK: - 订阅状态
    
    private var subscriptionSection: some View {
        Section {
            SubscriptionStatusCard()
        }
    }

    // MARK: - 显示偏好
    
    private var displayPreferencesSection: some View {
        Section {
            Picker(String(localized: "settings.display_mode"), selection: Binding(
                get: { settings.displayMode },
                set: { settings.displayMode = $0 }
            )) {
                ForEach(DisplayMode.allCases, id: \.self) { mode in
                    Text(mode.localizedDisplayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            
            Text(settings.displayMode.localizedDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
        } header: {
            Text(String(localized: "settings.display_preferences"))
        } footer: {
            Text(String(localized: "settings.display_preferences.footer"))
        }
    }

    // MARK: - 血糖偏好

    private var glucosePreferencesSection: some View {
        Section(String(localized: "settings.glucose_preferences")) {
            // 单位选择
            NavigationLink {
                UnitPickerView()
            } label: {
                HStack {
                    Text(String(localized: "settings.unit"))
                    Spacer()
                    Text(settings.preferredUnit.rawValue)
                        .foregroundStyle(.secondary)
                }
            }

            // 标签管理（含阈值配置）
            NavigationLink {
                TagManagementView()
            } label: {
                HStack {
                    Text(String(localized: "settings.tags_and_targets"))
                    Spacer()
                    Text(tagManagementSummary)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var tagManagementSummary: String {
        let visibleCount = settings.visibleSceneTags.count
        return String(format: String(localized: "settings.scenes_count"), visibleCount)
    }

    // MARK: - 数据同步

    private var dataSyncSection: some View {
        Section(String(localized: "settings.data_sync")) {
            HStack {
                Label(String(localized: "settings.health_sync"), systemImage: "heart.fill")
                    .foregroundStyle(.primary)
                Spacer()
                if settings.healthKitSyncEnabled {
                    Text(String(localized: "profile.connected"))
                        .font(.caption)
                        .foregroundStyle(.green)
                } else {
                    Button(String(localized: "profile.connect")) {
                        Task {
                            try? await healthKitManager.requestAuthorization()
                            settings.healthKitSyncEnabled = healthKitManager.isAuthorized
                        }
                    }
                    .font(.caption)
                }
            }

            NavigationLink {
                SyncSettingsView()
            } label: {
                HStack {
                    Label(String(localized: "profile.icloud"), systemImage: "icloud")
                    Spacer()
                    SyncStatusBadge()
                }
            }
        }
    }

    // MARK: - 数据管理

    private var dataManagementSection: some View {
        Section(String(localized: "settings.data_management")) {
            #if DEBUG
            NavigationLink {
                QuickTestDataView()
            } label: {
                Label(String(localized: "settings.test_data_generator"), systemImage: "hammer.fill")
                    .foregroundStyle(.orange)
            }
            
            NavigationLink {
                SyncDebugView()
            } label: {
                Label(String(localized: "settings.sync_debug"), systemImage: "ladybug.fill")
                    .foregroundStyle(.purple)
            }
            #endif
            
            NavigationLink {
                PDFPreviewView()
            } label: {
                Label(String(localized: "profile.export_pdf"), systemImage: "doc.richtext")
            }

            NavigationLink {
                CSVExportView()
            } label: {
                Label(String(localized: "profile.export_csv"), systemImage: "tablecells")
            }
            
            NavigationLink {
                FactoryResetView()
            } label: {
                Label(String(localized: "settings.clear_history"), systemImage: "trash.fill")
                    .foregroundStyle(.red)
            }
        }
    }

    // MARK: - 关于

    private var aboutSection: some View {
        Section(String(localized: "profile.about")) {
            HStack {
                Text(String(localized: "profile.version"))
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                    .foregroundStyle(.secondary)
            }

            NavigationLink {
                AboutView(type: .privacy)
            } label: {
                Text(String(localized: "profile.privacy"))
            }

            NavigationLink {
                AboutView(type: .disclaimer)
            } label: {
                Text(String(localized: "profile.disclaimer"))
            }

            NavigationLink {
                MedicalReferencesView()
            } label: {
                Text(String(localized: "profile.references"))
            }

            Button(action: requestReview) {
                Text(String(localized: "profile.rate"))
            }
        }
    }

    private func requestReview() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            AppStore.requestReview(in: windowScene)
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [GlucoseRecord.self, UserSettings.self], inMemory: true)
        .environment(HealthKitManager())
        .environment(SubscriptionManager())
}
