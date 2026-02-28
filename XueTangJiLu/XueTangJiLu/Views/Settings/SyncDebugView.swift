//
//  SyncDebugView.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/22.
//

#if DEBUG
import SwiftUI
import CloudKit
import SwiftData

/// 同步调试工具视图（仅 DEBUG 模式）
struct SyncDebugView: View {
    @Environment(CloudKitSyncManager.self) private var syncManager
    @Environment(\.modelContext) private var modelContext
    @State private var simulatedError: SimulatedError?
    @State private var glucoseCount: Int = 0
    @State private var medicationCount: Int = 0
    @State private var mealCount: Int = 0
    @State private var userSettingsCount: Int = 0
    
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
            // 数据统计
            dataStatisticsSection
            
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
                        type: .downloadFromCloud,
                        isSuccess: true,
                        glucoseCount: 3
                    )
                    syncManager.syncHistory.insert(event, at: 0)
                }
                
                Button("添加失败记录") {
                    let event = CloudKitSyncManager.SyncEvent(
                        type: .uploadToCloud,
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
                
                Button("刷新数据统计") {
                    refreshDataCounts()
                }
            }
            
            Section("当前状态信息") {
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(label: "同步状态", value: stateDescription)
                    InfoRow(label: "最后同步", value: syncManager.lastSyncTimeString)
                    InfoRow(label: "待同步", value: syncManager.hasPendingChanges ? "是" : "否")
                    InfoRow(label: "历史记录", value: "\(syncManager.syncHistory.count)")
                    InfoRow(label: "同步开关", value: syncManager.isSyncEnabled ? "开启" : "关闭")
                    InfoRow(label: "WiFi限制", value: syncManager.wifiOnlySync ? "是" : "否")
                    InfoRow(label: "初始导入", value: syncManager.isPerformingInitialImport ? "进行中" : "否")
                }
                .font(.caption)
            }
        }
        .navigationTitle("同步调试工具")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            refreshDataCounts()
        }
    }
    
    // MARK: - Data Statistics Section
    
    private var dataStatisticsSection: some View {
        Section("本地数据统计") {
            HStack {
                Label("血糖记录", systemImage: "heart.text.square")
                Spacer()
                Text("\(glucoseCount) 条")
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Label("用药记录", systemImage: "pills")
                Spacer()
                Text("\(medicationCount) 条")
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Label("饮食记录", systemImage: "fork.knife")
                Spacer()
                Text("\(mealCount) 条")
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Label("用户设置", systemImage: "gearshape")
                Spacer()
                Text("\(userSettingsCount) 个")
                    .foregroundStyle(userSettingsCount == 1 ? Color.secondary : Color.red)
            }
            
            if glucoseCount == 0 && medicationCount == 0 && mealCount == 0 {
                Text("⚠️ 本地没有任何数据！如果刚删除重装，检查 iCloud 是否正在同步。")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func refreshDataCounts() {
        Task { @MainActor in
            do {
                let glucoseDescriptor = FetchDescriptor<GlucoseRecord>()
                glucoseCount = try modelContext.fetchCount(glucoseDescriptor)
                
                let medicationDescriptor = FetchDescriptor<MedicationRecord>()
                medicationCount = try modelContext.fetchCount(medicationDescriptor)
                
                let mealDescriptor = FetchDescriptor<MealRecord>()
                mealCount = try modelContext.fetchCount(mealDescriptor)
                
                let settingsDescriptor = FetchDescriptor<UserSettings>()
                userSettingsCount = try modelContext.fetchCount(settingsDescriptor)
                
                print("📊 [数据统计] 血糖:\(glucoseCount) 用药:\(medicationCount) 饮食:\(mealCount) 设置:\(userSettingsCount)")
            } catch {
                print("❌ 统计数据失败: \(error)")
            }
        }
    }
    
    private var stateDescription: String {
        switch syncManager.currentState {
        case .idle:
            return "空闲"
        case .syncing:
            return "同步中"
        case .importing:
            return "从 iCloud 导入中"
        case .exporting:
            return "上传到 iCloud 中"
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
