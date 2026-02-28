//
//  CloudKitDiagnosticsView.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/26.
//

import SwiftUI
import SwiftData
import CloudKit

/// CloudKit 诊断视图
struct CloudKitDiagnosticsView: View {
    @Environment(CloudKitSyncManager.self) private var syncManager
    @Environment(\.modelContext) private var modelContext
    @State private var isRunningDiagnostics = false
    @State private var diagnosticResults: [DiagnosticResult] = []
    @State private var isQueryingCloud = false
    @State private var cloudRecordCounts: CloudRecordCounts?
    @State private var localRecordCounts: LocalRecordCounts?
    
    struct CloudRecordCounts {
        var glucose: Int = 0
        var medication: Int = 0
        var meal: Int = 0
        var userSettings: Int = 0
        var error: String?
        var total: Int { glucose + medication + meal + userSettings }
    }
    
    struct LocalRecordCounts {
        var glucose: Int = 0
        var medication: Int = 0
        var meal: Int = 0
        var userSettings: Int = 0
        var total: Int { glucose + medication + meal + userSettings }
    }
    
    struct DiagnosticResult: Identifiable {
        let id = UUID()
        let title: String
        let status: Status
        let details: String
        
        enum Status {
            case success
            case warning
            case error
            case info
            
            var icon: String {
                switch self {
                case .success: return "checkmark.circle.fill"
                case .warning: return "exclamationmark.triangle.fill"
                case .error: return "xmark.circle.fill"
                case .info: return "info.circle.fill"
                }
            }
            
            var color: Color {
                switch self {
                case .success: return .green
                case .warning: return .orange
                case .error: return .red
                case .info: return .blue
                }
            }
        }
    }
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("CloudKit 诊断")
                        .font(.headline)
                    Text("检查 CloudKit 配置和连接状态")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            
            Section("账户信息") {
                HStack {
                    Text("iCloud 账户状态")
                    Spacer()
                    statusBadge(for: syncManager.iCloudAccountStatus)
                }
                
                HStack {
                    Text("Container ID")
                    Spacer()
                    Text("iCloud.com.xxl.XueTangJiLu")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("App Group")
                    Spacer()
                    Text("group.com.xxl.XueTangJiLu")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // 云端 vs 本地 数据对比
            Section("数据对比（云端 vs 本地）") {
                if let cloud = cloudRecordCounts, let local = localRecordCounts {
                    recordCompareRow(label: "血糖记录", cloud: cloud.glucose, local: local.glucose)
                    recordCompareRow(label: "用药记录", cloud: cloud.medication, local: local.medication)
                    recordCompareRow(label: "饮食记录", cloud: cloud.meal, local: local.meal)
                    recordCompareRow(label: "用户设置", cloud: cloud.userSettings, local: local.userSettings)
                    
                    if cloud.total == 0 {
                        Text("⚠️ CloudKit 云端没有任何数据记录！\n数据可能从未成功上传。请在有数据的设备上确保网络畅通，等待上传完成后再尝试在其他设备同步。")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .padding(.vertical, 4)
                    } else if cloud.total > local.total {
                        Text("☁️ 云端有 \(cloud.total - local.total) 条记录尚未同步到本地，请稍等或点击「立即同步」。")
                            .font(.caption)
                            .foregroundStyle(.blue)
                            .padding(.vertical, 4)
                    } else if cloud.total == local.total {
                        Text("✅ 云端和本地数据一致")
                            .font(.caption)
                            .foregroundStyle(.green)
                            .padding(.vertical, 4)
                    }
                    
                    if let error = cloud.error {
                        Text("查询错误: \(error)")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                } else if isQueryingCloud {
                    HStack {
                        ProgressView()
                            .controlSize(.small)
                        Text("正在查询云端数据...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("点击下方按钮查询")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Button(action: queryCloudAndLocalCounts) {
                    HStack {
                        if isQueryingCloud {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "icloud.and.arrow.down")
                        }
                        Text(isQueryingCloud ? "查询中..." : "查询云端记录数量")
                    }
                }
                .disabled(isQueryingCloud || syncManager.iCloudAccountStatus != .available)
            }
            
            if !diagnosticResults.isEmpty {
                Section("诊断结果") {
                    ForEach(diagnosticResults) { result in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: result.status.icon)
                                    .foregroundStyle(result.status.color)
                                Text(result.title)
                                    .font(.subheadline)
                            }
                            
                            Text(result.details)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            
            Section {
                Button(action: runDiagnostics) {
                    HStack {
                        if isRunningDiagnostics {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "stethoscope")
                        }
                        Text(isRunningDiagnostics ? "正在诊断..." : "运行完整诊断")
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(isRunningDiagnostics)
            }
            
            Section("解决方案") {
                VStack(alignment: .leading, spacing: 12) {
                    solutionRow(
                        icon: "icloud",
                        title: "检查 iCloud 登录",
                        description: "设置 → Apple ID → iCloud → 确认已登录"
                    )
                    
                    solutionRow(
                        icon: "app.badge",
                        title: "启用应用同步",
                        description: "设置 → Apple ID → iCloud → 使用 iCloud 的 App → 打开本应用"
                    )
                    
                    solutionRow(
                        icon: "arrow.clockwise",
                        title: "重新安装应用",
                        description: "完全删除应用后重新安装，可以清除损坏的同步状态"
                    )
                }
            }
        }
        .navigationTitle("CloudKit 诊断")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // 页面加载时自动运行一次诊断
            if diagnosticResults.isEmpty {
                await runDiagnosticsAsync()
            }
        }
    }
    
    private func statusBadge(for status: CKAccountStatus) -> some View {
        let (text, color) = statusInfo(for: status)
        return Text(text)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
    
    private func statusInfo(for status: CKAccountStatus) -> (String, Color) {
        switch status {
        case .available:
            return ("可用", .green)
        case .noAccount:
            return ("未登录", .red)
        case .restricted:
            return ("受限制", .orange)
        case .couldNotDetermine:
            return ("未知", .gray)
        case .temporarilyUnavailable:
            return ("暂时不可用", .orange)
        @unknown default:
            return ("未知状态", .gray)
        }
    }
    
    private func solutionRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func recordCompareRow(label: String, cloud: Int, local: Int) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            Text("☁️ \(cloud)")
                .font(.caption)
                .foregroundStyle(cloud > 0 ? .primary : .secondary)
            Text("/")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("📱 \(local)")
                .font(.caption)
                .foregroundStyle(local > 0 ? .primary : .secondary)
            
            if cloud == local {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            } else if cloud > local {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            } else {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
        }
    }
    
    private func queryCloudAndLocalCounts() {
        isQueryingCloud = true
        Task {
            // 查询本地数据
            await queryLocalCounts()
            // 查询云端数据
            await queryCloudCounts()
            isQueryingCloud = false
        }
    }
    
    @MainActor
    private func queryLocalCounts() async {
        var counts = LocalRecordCounts()
        do {
            counts.glucose = try modelContext.fetchCount(FetchDescriptor<GlucoseRecord>())
            counts.medication = try modelContext.fetchCount(FetchDescriptor<MedicationRecord>())
            counts.meal = try modelContext.fetchCount(FetchDescriptor<MealRecord>())
            counts.userSettings = try modelContext.fetchCount(FetchDescriptor<UserSettings>())
        } catch {
            #if DEBUG
            print("❌ 本地数据统计失败: \(error)")
            #endif
        }
        localRecordCounts = counts
    }
    
    /// 通过 Zone Changes 统计云端记录数（不依赖查询索引）
    private func queryCloudCounts() async {
        let container = CKContainer(identifier: AppConstants.cloudKitContainerID)
        let database = container.privateCloudDatabase
        let zoneID = CKRecordZone.ID(
            zoneName: "com.apple.coredata.cloudkit.zone",
            ownerName: CKCurrentUserDefaultName
        )
        
        do {
            let typeCounts = try await fetchAllRecordCountsInZone(database: database, zoneID: zoneID)
            
            var counts = CloudRecordCounts()
            counts.glucose = typeCounts["CD_GlucoseRecord"] ?? 0
            counts.medication = typeCounts["CD_MedicationRecord"] ?? 0
            counts.meal = typeCounts["CD_MealRecord"] ?? 0
            counts.userSettings = typeCounts["CD_UserSettings"] ?? 0
            
            #if DEBUG
            for (type, count) in typeCounts.sorted(by: { $0.key < $1.key }) {
                print("☁️ [CloudKit] \(type): \(count) 条记录")
            }
            #endif
            
            await MainActor.run {
                cloudRecordCounts = counts
            }
        } catch {
            #if DEBUG
            print("❌ [CloudKit] 查询云端记录失败: \(error.localizedDescription)")
            #endif
            
            await MainActor.run {
                var counts = CloudRecordCounts()
                counts.error = error.localizedDescription
                cloudRecordCounts = counts
            }
        }
    }
    
    /// 使用 CKFetchRecordZoneChangesOperation 遍历 Zone 内所有记录并按类型计数
    /// 此方法不需要 CloudKit 查询索引
    private func fetchAllRecordCountsInZone(
        database: CKDatabase,
        zoneID: CKRecordZone.ID
    ) async throws -> [String: Int] {
        var allCounts: [String: Int] = [:]
        var changeToken: CKServerChangeToken? = nil
        var hasMore = true
        
        while hasMore {
            let result = try await fetchOneZoneChangeBatch(
                database: database,
                zoneID: zoneID,
                since: changeToken
            )
            
            for (type, count) in result.counts {
                allCounts[type, default: 0] += count
            }
            changeToken = result.newToken
            hasMore = result.moreComing
        }
        
        return allCounts
    }
    
    private struct ZoneChangeBatchResult {
        let counts: [String: Int]
        let newToken: CKServerChangeToken?
        let moreComing: Bool
    }
    
    private func fetchOneZoneChangeBatch(
        database: CKDatabase,
        zoneID: CKRecordZone.ID,
        since token: CKServerChangeToken?
    ) async throws -> ZoneChangeBatchResult {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ZoneChangeBatchResult, Error>) in
            var recordCounts: [String: Int] = [:]
            var newToken: CKServerChangeToken?
            var moreComing = false
            
            let config = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
            config.previousServerChangeToken = token
            config.desiredKeys = []
            
            let operation = CKFetchRecordZoneChangesOperation(
                recordZoneIDs: [zoneID],
                configurationsByRecordZoneID: [zoneID: config]
            )
            
            operation.recordWasChangedBlock = { _, result in
                if case .success(let record) = result {
                    recordCounts[record.recordType, default: 0] += 1
                }
            }
            
            operation.recordZoneFetchResultBlock = { _, result in
                if case .success(let (serverToken, _, more)) = result {
                    newToken = serverToken
                    moreComing = more
                }
            }
            
            operation.fetchRecordZoneChangesResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume(returning: ZoneChangeBatchResult(
                        counts: recordCounts,
                        newToken: newToken,
                        moreComing: moreComing
                    ))
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            database.add(operation)
        }
    }
    
    private func runDiagnostics() {
        Task {
            await runDiagnosticsAsync()
        }
    }
    
    private func runDiagnosticsAsync() async {
        isRunningDiagnostics = true
        diagnosticResults.removeAll()
        
        // 1. 检查账户状态
        await syncManager.checkAccountStatus()
        
        let accountStatus = syncManager.iCloudAccountStatus
        if accountStatus == .available {
            diagnosticResults.append(DiagnosticResult(
                title: "iCloud 账户",
                status: .success,
                details: "已登录并可用"
            ))
        } else {
            diagnosticResults.append(DiagnosticResult(
                title: "iCloud 账户",
                status: .error,
                details: statusInfo(for: accountStatus).0
            ))
        }
        
        // 2. 检查网络连接
        if syncManager.networkMonitor.isConnected {
            let networkType = syncManager.networkMonitor.isUsingWiFi ? "WiFi" : "蜂窝网络"
            diagnosticResults.append(DiagnosticResult(
                title: "网络连接",
                status: .success,
                details: "已连接 (\(networkType))"
            ))
        } else {
            diagnosticResults.append(DiagnosticResult(
                title: "网络连接",
                status: .error,
                details: "无网络连接"
            ))
        }
        
        // 3. 检查同步设置
        if syncManager.isSyncEnabled {
            diagnosticResults.append(DiagnosticResult(
                title: "同步功能",
                status: .success,
                details: "已启用"
            ))
        } else {
            diagnosticResults.append(DiagnosticResult(
                title: "同步功能",
                status: .warning,
                details: "已禁用"
            ))
        }
        
        // 4. 检查 WiFi 限制
        if syncManager.wifiOnlySync {
            if syncManager.networkMonitor.isUsingWiFi {
                diagnosticResults.append(DiagnosticResult(
                    title: "WiFi 同步",
                    status: .success,
                    details: "已启用 WiFi 限制，当前使用 WiFi"
                ))
            } else {
                diagnosticResults.append(DiagnosticResult(
                    title: "WiFi 同步",
                    status: .warning,
                    details: "已启用 WiFi 限制，当前未使用 WiFi"
                ))
            }
        }
        
        // 5. 检查最后同步时间
        if let lastSync = syncManager.lastSyncDate {
            let timeAgo = Date().timeIntervalSince(lastSync)
            let status: DiagnosticResult.Status = timeAgo < 3600 ? .success : .warning
            diagnosticResults.append(DiagnosticResult(
                title: "最后同步",
                status: status,
                details: syncManager.lastSyncTimeString
            ))
        } else {
            diagnosticResults.append(DiagnosticResult(
                title: "最后同步",
                status: .info,
                details: "从未同步"
            ))
        }
        
        // 6. 检查 CloudKit 容器
        do {
            let container = CKContainer(identifier: "iCloud.com.xxl.XueTangJiLu")
            let _ = try await container.accountStatus()
            
            diagnosticResults.append(DiagnosticResult(
                title: "CloudKit 容器",
                status: .success,
                details: "容器连接正常"
            ))
            
            // 尝试获取用户记录
            do {
                let userRecordID = try await container.userRecordID()
                diagnosticResults.append(DiagnosticResult(
                    title: "用户记录",
                    status: .success,
                    details: "ID: \(userRecordID.recordName.prefix(12))..."
                ))
            } catch {
                diagnosticResults.append(DiagnosticResult(
                    title: "用户记录",
                    status: .error,
                    details: error.localizedDescription
                ))
            }
        } catch {
            diagnosticResults.append(DiagnosticResult(
                title: "CloudKit 容器",
                status: .error,
                details: error.localizedDescription
            ))
        }
        
        // 等待一下让动画更自然
        try? await Task.sleep(for: .seconds(0.5))
        isRunningDiagnostics = false
    }
}

#Preview {
    NavigationStack {
        CloudKitDiagnosticsView()
            .environment(CloudKitSyncManager())
    }
}
