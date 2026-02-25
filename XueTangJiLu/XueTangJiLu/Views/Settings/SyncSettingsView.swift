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
    @Environment(\.modelContext) private var modelContext
    
    @State private var showError: Error?
    @State private var isSyncing = false
    
    var body: some View {
        Form {
            // 账户状态
            accountStatusSection
            
            // 同步控制
            syncControlSection
            
            // 同步历史
            syncHistorySection
        }
        .navigationTitle(String(localized: "sync.title"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: Binding(
            get: { showError.map { ErrorWrapper(error: $0) } },
            set: { showError = $0?.error }
        )) { wrapper in
            SyncErrorView(error: wrapper.error)
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
                set: { syncManager.isSyncEnabled = $0 }
            ))
            
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
            
            if syncManager.lastSyncDate != nil {
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
            Text(String(localized: "sync.footer"))
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
                try await syncManager.manualSync()
                try await Task.sleep(for: .seconds(2))
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
                    HStack {
                        Image(systemName: event.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(event.isSuccess ? .green : .red)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.type.rawValue)
                                .font(.subheadline)
                            
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
                }
            }
        } header: {
            Text(String(localized: "sync.history"))
        } footer: {
            Text(String(localized: "sync.history_footer"))
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
