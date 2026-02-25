//
//  SyncDebugView.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/22.
//

#if DEBUG
import SwiftUI
import CloudKit

/// 同步调试工具视图（仅 DEBUG 模式）
struct SyncDebugView: View {
    @Environment(CloudKitSyncManager.self) private var syncManager
    @State private var simulatedError: SimulatedError?
    
    enum SimulatedError: String, CaseIterable, Identifiable {
        case notAuthenticated = "未登录 iCloud"
        case networkFailure = "网络故障"
        case quotaExceeded = "配额超限"
        case serverError = "服务器错误"
        
        var id: String { rawValue }
        
        var ckError: CKError {
            switch self {
            case .notAuthenticated:
                return CKError(.notAuthenticated)
            case .networkFailure:
                return CKError(.networkFailure)
            case .quotaExceeded:
                return CKError(.quotaExceeded)
            case .serverError:
                return CKError(.serviceUnavailable)
            }
        }
    }
    
    var body: some View {
        Form {
            Section("同步状态模拟") {
                Button("模拟同步开始") {
                    syncManager.currentState = .syncing
                }
                
                Button("模拟同步成功") {
                    syncManager.currentState = .success(Date())
                    syncManager.lastSyncDate = Date()
                }
                
                Button("重置为空闲状态") {
                    syncManager.currentState = .idle
                }
            }
            
            Section("错误模拟") {
                ForEach(SimulatedError.allCases) { error in
                    Button(error.rawValue) {
                        syncManager.currentState = .failed(error.ckError)
                    }
                }
            }
            
            Section("同步历史模拟") {
                Button("添加成功记录") {
                    let event = CloudKitSyncManager.SyncEvent(
                        type: .importData,
                        isSuccess: true
                    )
                    syncManager.syncHistory.insert(event, at: 0)
                }
                
                Button("添加失败记录") {
                    let event = CloudKitSyncManager.SyncEvent(
                        type: .exportData,
                        isSuccess: false,
                        errorMessage: "模拟的同步错误"
                    )
                    syncManager.syncHistory.insert(event, at: 0)
                }
                
                Button("清除所有记录", role: .destructive) {
                    syncManager.clearSyncHistory()
                }
            }
            
            Section("账户状态模拟") {
                Picker("iCloud 账户状态", selection: Binding(
                    get: { syncManager.iCloudAccountStatus },
                    set: { syncManager.iCloudAccountStatus = $0 }
                )) {
                    Text("已登录").tag(CKAccountStatus.available)
                    Text("未登录").tag(CKAccountStatus.noAccount)
                    Text("受限制").tag(CKAccountStatus.restricted)
                    Text("检查中").tag(CKAccountStatus.couldNotDetermine)
                }
            }
            
            Section("网络状态") {
                HStack {
                    Text("当前网络")
                    Spacer()
                    Text(syncManager.networkMonitor.connectionType)
                        .foregroundStyle(.secondary)
                }
                
                Toggle("模拟离线", isOn: Binding(
                    get: { !syncManager.networkMonitor.isConnected },
                    set: { syncManager.networkMonitor.isConnected = !$0 }
                ))
            }
            
            Section("快捷操作") {
                Button("打开 CloudKit Dashboard") {
                    if let url = URL(string: "https://icloud.developer.apple.com/dashboard") {
                        UIApplication.shared.open(url)
                    }
                }
                
                Button("查看同步容器") {
                    print("容器 ID: \(AppConstants.cloudKitContainerID)")
                    print("App Group: \(AppConstants.appGroupID)")
                }
            }
            
            Section("当前状态信息") {
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(label: "同步状态", value: stateDescription)
                    InfoRow(label: "最后同步", value: syncManager.lastSyncTimeString)
                    InfoRow(label: "待同步数", value: "\(syncManager.pendingOperations)")
                    InfoRow(label: "历史记录", value: "\(syncManager.syncHistory.count)")
                    InfoRow(label: "同步开关", value: syncManager.isSyncEnabled ? "开启" : "关闭")
                    InfoRow(label: "WiFi限制", value: syncManager.wifiOnlySync ? "是" : "否")
                }
                .font(.caption)
            }
        }
        .navigationTitle("同步调试工具")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var stateDescription: String {
        switch syncManager.currentState {
        case .idle:
            return "空闲"
        case .syncing:
            return "同步中"
        case .success(let date):
            return "成功 (\(date.formatted(.relative(presentation: .named))))"
        case .failed(let error):
            return "失败: \(error.localizedDescription)"
        }
    }
}

private struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
    }
}

#Preview {
    NavigationStack {
        SyncDebugView()
            .environment(CloudKitSyncManager())
    }
}
#endif
