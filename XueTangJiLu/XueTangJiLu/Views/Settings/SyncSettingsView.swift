//
//  SyncSettingsView.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/22.
//

import SwiftUI
import SwiftData
import CloudKit

/// iCloud 同步设置页面
struct SyncSettingsView: View {
    @Environment(CloudKitSyncManager.self) private var syncManager
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(\.modelContext) private var modelContext
    
    @State private var showError: Error?
    @State private var isSyncing = false
    @State private var showRestartAlert = false
    @State private var pendingSyncEnabled: Bool?
    @State private var showPaywall = false
    
    var body: some View {
        Form {
            // 功能锁定提示（免费用户）
            if !FeatureManager.canAccessFeature(.iCloudSync, isPremium: subscriptionManager.isPremiumUser) {
                Section {
                    FeatureLockBanner(feature: .iCloudSync)
                }
            }
            
            // iCloud 配额超限警告
            if syncManager.isQuotaExceeded {
                Section {
                    VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
                        Label(String(localized: "sync.quota.title"), systemImage: "externaldrive.badge.exclamationmark")
                            .font(.headline)
                            .foregroundStyle(.orange)
                        
                        Text(String(localized: "sync.quota.message"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Button {
                            if let url = URL(string: "App-prefs:CASTLE") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Text(String(localized: "sync.quota.manage"))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding(.top, AppConstants.Spacing.xs)
                    }
                    .padding(.vertical, AppConstants.Spacing.xs)
                }
            }
            
            // 账户状态
            accountStatusSection
            
            // 同步控制
            syncControlSection
            
            #if DEBUG
            // 诊断工具
            diagnosticsSection
            #endif
            
            // 同步历史 - 只在账户可用时显示
            if syncManager.iCloudAccountStatus == .available {
                syncHistorySection
            }
        }
        .navigationTitle(String(localized: "sync.title"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: Binding(
            get: { showError.map { ErrorWrapper(error: $0) } },
            set: { showError = $0?.error }
        )) { wrapper in
            SyncErrorView(error: wrapper.error)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .alert(String(localized: "sync.restart.title"), isPresented: $showRestartAlert) {
            Button(String(localized: "common.cancel"), role: .cancel) {
                if let pending = pendingSyncEnabled {
                    syncManager.isSyncEnabled = !pending
                    pendingSyncEnabled = nil
                }
            }
            Button(String(localized: "sync.restart.confirm")) {
                if let pending = pendingSyncEnabled {
                    syncManager.isSyncEnabled = pending
                    pendingSyncEnabled = nil
                }
            }
        } message: {
            Text(String(localized: "sync.restart.message \(syncManager.isSyncEnabled ? String(localized: "sync.restart.enabled") : String(localized: "sync.restart.disabled")) \(pendingSyncEnabled == true ? String(localized: "sync.restart.enabled") : String(localized: "sync.restart.disabled"))"))
        }
    }
    
    // MARK: - Account Status Section
    
    private var accountStatusSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: AppConstants.Spacing.xs) {
                    Text(String(localized: "sync.account"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text(accountStatusText)
                        .font(.body)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                Image(systemName: accountStatusIcon)
                    .font(.title2)
                    .foregroundStyle(accountStatusColor)
            }
            .padding(.vertical, AppConstants.Spacing.xs)
            
            HStack {
                VStack(alignment: .leading, spacing: AppConstants.Spacing.xs) {
                    Text(String(localized: "sync.network"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text(syncManager.networkMonitor.connectionType)
                        .font(.body)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                Image(systemName: networkIcon)
                    .font(.title2)
                    .foregroundStyle(networkColor)
            }
            .padding(.vertical, AppConstants.Spacing.xs)
        } header: {
            Text(String(localized: "sync.status"))
        }
    }
    
    private var accountStatusText: String {
        switch syncManager.iCloudAccountStatus {
        case .available:
            return String(localized: "sync.logged_in")
        case .noAccount:
            return String(localized: "sync.not_logged_in")
        case .restricted:
            return String(localized: "sync.restricted")
        case .couldNotDetermine:
            return String(localized: "sync.checking")
        case .temporarilyUnavailable:
            return String(localized: "sync.temporarily_unavailable")
        @unknown default:
            return String(localized: "sync.unknown_status")
        }
    }
    
    private var accountStatusIcon: String {
        switch syncManager.iCloudAccountStatus {
        case .available:
            return "checkmark.circle.fill"
        case .noAccount:
            return "xmark.circle.fill"
        case .restricted:
            return "exclamationmark.triangle.fill"
        default:
            return "questionmark.circle.fill"
        }
    }
    
    private var accountStatusColor: Color {
        switch syncManager.iCloudAccountStatus {
        case .available:
            return .green
        case .noAccount, .restricted:
            return .red
        default:
            return .orange
        }
    }
    
    private var networkIcon: String {
        if !syncManager.networkMonitor.isConnected {
            return "wifi.slash"
        } else if syncManager.networkMonitor.isUsingWiFi {
            return "wifi"
        } else if syncManager.networkMonitor.isUsingCellular {
            return "antenna.radiowaves.left.and.right"
        } else {
            return "network"
        }
    }
    
    private var networkColor: Color {
        syncManager.networkMonitor.isConnected ? .green : .orange
    }
    
    // MARK: - Sync Control Section
    
    private var syncControlSection: some View {
        Section {
            Toggle(String(localized: "sync.enable"), isOn: Binding(
                get: { syncManager.isSyncEnabled },
                set: { newValue in
                    // 检查付费权限
                    if !FeatureManager.canAccessFeature(.iCloudSync, isPremium: subscriptionManager.isPremiumUser) {
                        showPaywall = true
                        return
                    }
                    
                    // 检测到同步开关变化
                    if newValue != syncManager.isSyncEnabled {
                        pendingSyncEnabled = newValue
                        showRestartAlert = true
                    }
                }
            ))
            .disabled(!FeatureManager.canAccessFeature(.iCloudSync, isPremium: subscriptionManager.isPremiumUser))
            
            Toggle(String(localized: "sync.wifi_only"), isOn: Binding(
                get: { syncManager.wifiOnlySync },
                set: { syncManager.wifiOnlySync = $0 }
            ))
            .disabled(!syncManager.isSyncEnabled)
            
            Button(action: performManualSync) {
                HStack {
                    Label(String(localized: "sync.sync_now"), systemImage: "arrow.triangle.2.circlepath")
                    
                    Spacer()
                    
                    if isSyncing {
                        ProgressView()
                    }
                }
            }
            .disabled(!canManualSync || isSyncing)
            
            // 同步状态实时显示
            if syncManager.isPerformingInitialImport {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text(String(localized: "sync.state.importing_download"))
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
                .padding(.vertical, 4)
            } else if case .importing = syncManager.currentState {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text(String(localized: "sync.state.importing"))
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
                .padding(.vertical, 4)
            } else if case .exporting = syncManager.currentState {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text(String(localized: "sync.state.exporting"))
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
                .padding(.vertical, 4)
            }
            
            if syncManager.iCloudAccountStatus == .available && syncManager.lastSyncDate != nil {
                HStack {
                    Text(String(localized: "sync.last_sync"))
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(syncManager.lastSyncTimeString)
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            }
        } header: {
            Text(String(localized: "sync.settings"))
        } footer: {
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "sync.footer"))
                
                Text(String(localized: "sync.restart_warning"))
                    .foregroundStyle(.orange)
                    .font(.caption)
                
                Text(String(localized: "sync.first_sync_tip"))
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
    }
    
    // MARK: - Diagnostics Section
    
    private var diagnosticsSection: some View {
        Section {
            NavigationLink(destination: CloudKitDiagnosticsView()) {
                Label("CloudKit 诊断", systemImage: "stethoscope")
            }
            
            NavigationLink(destination: SyncDebugView()) {
                Label("同步调试", systemImage: "wrench.and.screwdriver")
            }
        } header: {
            Text("诊断工具")
        } footer: {
            Text("使用诊断工具检查 CloudKit 配置和同步问题")
        }
    }
    
    private var canManualSync: Bool {
        syncManager.isSyncEnabled &&
        syncManager.networkMonitor.isConnected &&
        syncManager.iCloudAccountStatus == .available &&
        (!syncManager.wifiOnlySync || syncManager.networkMonitor.isUsingWiFi)
    }
    
    private func performManualSync() {
        isSyncing = true
        Task {
            do {
                try await syncManager.manualSync(modelContext: modelContext)
            } catch {
                showError = error
            }
            isSyncing = false
        }
    }
    
    // MARK: - Sync History Section
    
    private var syncHistorySection: some View {
        Section {
            if syncManager.syncHistory.isEmpty {
                Text(String(localized: "sync.no_history"))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(syncManager.syncHistory.prefix(10)) { event in
                    HStack(spacing: AppConstants.Spacing.md) {
                        // 成功/失败图标
                        Image(systemName: event.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(event.isSuccess ? .green : .red)
                        
                        // 方向图标
                        Image(systemName: syncDirectionIcon(for: event.type))
                            .foregroundStyle(.blue)
                            .font(.caption)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.type.localizedString)
                                .font(.subheadline)
                            
                            if let countString = event.formattedCountString() {
                                Text(countString)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            if let deletedString = event.formattedDeletedCountString() {
                                Text(deletedString)
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                            
                            Text(event.timestamp, style: .relative)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            if let error = event.errorMessage {
                                Text(error)
                                    .font(.caption2)
                                    .foregroundStyle(.red)
                                    .lineLimit(1)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 2)
                }
            }
        } header: {
            Text(String(localized: "sync.history"))
        } footer: {
            Text(String(localized: "sync.history_footer"))
        }
    }
    
    private func syncDirectionIcon(for type: CloudKitSyncManager.SyncEvent.EventType) -> String {
        switch type {
        case .downloadFromCloud:
            return "icloud.and.arrow.down"
        case .uploadToCloud:
            return "icloud.and.arrow.up"
        case .setup:
            return "gearshape"
        case .manualSync:
            return "arrow.triangle.2.circlepath"
        }
    }
}

// MARK: - Helper Types

private struct ErrorWrapper: Identifiable {
    let id = UUID()
    let error: Error
}

#Preview {
    NavigationStack {
        SyncSettingsView()
            .environment(CloudKitSyncManager())
    }
}
