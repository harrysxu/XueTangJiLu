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
        case .syncing:
            return .blue
        case .success:
            return .green
        case .failed:
            return .red
        }
    }
    
    private var statusText: String {
        if !syncManager.networkMonitor.isConnected {
            return "离线"
        }
        
        switch syncManager.currentState {
        case .idle:
            return ""
        case .syncing:
            return "同步中"
        case .success:
            return "已同步"
        case .failed:
            return "失败"
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
                    Text("最后同步: \(syncManager.lastSyncTimeString)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            // 待同步数量
            if syncManager.pendingOperations > 0 {
                HStack {
                    Image(systemName: "circle.badge.exclamationmark")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text("\(syncManager.pendingOperations) 项待同步")
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
            return "已禁用"
        }
        
        if syncManager.iCloudAccountStatus != .available {
            return "未登录 iCloud"
        }
        
        if !syncManager.networkMonitor.isConnected {
            return "无网络连接"
        }
        
        switch syncManager.currentState {
        case .idle:
            return "就绪"
        case .syncing:
            return "正在同步"
        case .success:
            return "同步成功"
        case .failed(let error):
            return "失败: \(error.localizedDescription)"
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
