//
//  SyncStatusBadge.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/22.
//

import SwiftUI
import CloudKit

/// 同步状态徽章组件
struct SyncStatusBadge: View {
    @Environment(CloudKitSyncManager.self) private var syncManager
    
    var body: some View {
        HStack(spacing: 4) {
            statusIcon
                .foregroundStyle(statusColor)
            
            if showStatusText {
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(statusColor)
            }
        }
    }
    
    // MARK: - Private Properties
    
    private var statusIcon: some View {
        Group {
            switch syncManager.currentState {
            case .idle:
                Image(systemName: "icloud")
                
            case .syncing:
                Image(systemName: "icloud.and.arrow.up")
                    .symbolEffect(.pulse)
                
            case .importing:
                Image(systemName: "icloud.and.arrow.down")
                    .symbolEffect(.pulse)
                
            case .exporting:
                Image(systemName: "icloud.and.arrow.up")
                    .symbolEffect(.pulse)
                
            case .success:
                Image(systemName: "checkmark.icloud")
                
            case .failed:
                Image(systemName: "icloud.slash")
            }
        }
        .font(.caption)
    }
    
    private var statusColor: Color {
        if !syncManager.networkMonitor.isConnected {
            return .orange
        }
        
        switch syncManager.currentState {
        case .idle:
            return .secondary
        case .syncing, .importing, .exporting:
            return .blue
        case .success:
            return .green
        case .failed:
            return .red
        }
    }
    
    private var statusText: String {
        if !syncManager.networkMonitor.isConnected {
            return String(localized: "sync.status.offline")
        }
        
        switch syncManager.currentState {
        case .idle:
            return ""
        case .syncing:
            return String(localized: "sync.status.syncing")
        case .importing:
            return String(localized: "sync.status.downloading")
        case .exporting:
            return String(localized: "sync.status.uploading")
        case .success:
            return String(localized: "sync.status.synced")
        case .failed:
            return String(localized: "sync.status.failed")
        }
    }
    
    private var showStatusText: Bool {
        switch syncManager.currentState {
        case .idle:
            return false
        default:
            return true
        }
    }
}

/// 详细同步状态视图（用于设置页）
struct SyncStatusDetailView: View {
    @Environment(CloudKitSyncManager.self) private var syncManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
            // 状态行
            HStack {
                SyncStatusBadge()
                Spacer()
                Text(statusDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // 最后同步时间
            if syncManager.lastSyncDate != nil {
                HStack {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(String(localized: "sync.status.last_sync_format \(syncManager.lastSyncTimeString)"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            if syncManager.hasPendingChanges {
                HStack {
                    Image(systemName: "circle.badge.exclamationmark")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text(String(localized: "sync.status.pending_changes", defaultValue: "有待同步的变更"))
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(AppConstants.Spacing.md)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card)
                .stroke(Color(.separator), lineWidth: 0.5)
        )
    }
    
    private var statusDescription: String {
        if !syncManager.isSyncEnabled {
            return String(localized: "sync.status.disabled")
        }
        
        if syncManager.iCloudAccountStatus != .available {
            return String(localized: "sync.status.not_signed_in")
        }
        
        if !syncManager.networkMonitor.isConnected {
            return String(localized: "sync.status.no_network")
        }
        
        switch syncManager.currentState {
        case .idle:
            return String(localized: "sync.status.ready")
        case .syncing:
            return String(localized: "sync.status.syncing")
        case .importing:
            return String(localized: "sync.status.downloading")
        case .exporting:
            return String(localized: "sync.status.uploading")
        case .success:
            return String(localized: "sync.status.sync_success")
        case .failed(let error):
            return String(localized: "sync.status.failed_detail \(error.localizedDescription)")
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SyncStatusBadge()
        SyncStatusDetailView()
    }
    .padding()
    .environment(CloudKitSyncManager())
}
