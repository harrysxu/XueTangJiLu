//
//  CloudKitSyncManager.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/22.
//

import Foundation
import SwiftData
import CloudKit
import Observation
import CoreData
import os.log

/// CloudKit 同步管理器
@Observable
final class CloudKitSyncManager {
    
    // MARK: - Types
    
    /// 同步状态
    enum SyncState: Equatable {
        case idle
        case syncing
        case importing
        case exporting
        case success(Date)
        case failed(Error)
        
        static func == (lhs: SyncState, rhs: SyncState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.syncing, .syncing),
                 (.importing, .importing), (.exporting, .exporting):
                return true
            case let (.success(date1), .success(date2)):
                return date1 == date2
            case let (.failed(error1), .failed(error2)):
                return error1.localizedDescription == error2.localizedDescription
            default:
                return false
            }
        }
    }
    
    /// 同步事件记录
    struct SyncEvent: Identifiable, Codable {
        let id: UUID
        let timestamp: Date
        let type: EventType
        let isSuccess: Bool
        let errorMessage: String?
        
        let glucoseCount: Int?
        let medicationCount: Int?
        let mealCount: Int?
        
        enum EventType: String, Codable {
            case downloadFromCloud = "download"
            case uploadToCloud = "upload"
            case setup = "setup"
            case manualSync = "manual"
            
            var localizedKey: String {
                switch self {
                case .downloadFromCloud:
                    return "sync.event.download"
                case .uploadToCloud:
                    return "sync.event.upload"
                case .setup:
                    return "sync.event.setup"
                case .manualSync:
                    return "sync.event.manual_sync"
                }
            }
        }
        
        init(type: EventType, 
             isSuccess: Bool, 
             errorMessage: String? = nil,
             glucoseCount: Int? = nil,
             medicationCount: Int? = nil,
             mealCount: Int? = nil) {
            self.id = UUID()
            self.timestamp = Date()
            self.type = type
            self.isSuccess = isSuccess
            self.errorMessage = errorMessage
            self.glucoseCount = glucoseCount
            self.medicationCount = medicationCount
            self.mealCount = mealCount
        }
        
        var totalCount: Int {
            (glucoseCount ?? 0) + (medicationCount ?? 0) + (mealCount ?? 0)
        }
        
        var hasCountData: Bool {
            totalCount > 0
        }
        
        func formattedCountString() -> String? {
            guard hasCountData else { return nil }
            
            var parts: [String] = []
            
            if let count = glucoseCount, count > 0 {
                parts.append(String(localized: "sync.count.glucose", defaultValue: "\(count)条血糖"))
            }
            if let count = medicationCount, count > 0 {
                parts.append(String(localized: "sync.count.medication", defaultValue: "\(count)条用药"))
            }
            if let count = mealCount, count > 0 {
                parts.append(String(localized: "sync.count.meal", defaultValue: "\(count)条饮食"))
            }
            
            return parts.joined(separator: "，")
        }
    }
    
    // MARK: - Properties
    
    /// 当前同步状态
    var currentState: SyncState = .idle
    
    /// 最后同步时间
    var lastSyncDate: Date? {
        didSet {
            if let date = lastSyncDate {
                UserDefaults.standard.set(date, forKey: "cloudkit_last_sync_date")
            } else {
                UserDefaults.standard.removeObject(forKey: "cloudkit_last_sync_date")
            }
        }
    }
    
    /// iCloud 账户状态
    var iCloudAccountStatus: CKAccountStatus = .couldNotDetermine {
        didSet {
            // 如果账户不可用，清除同步数据
            if iCloudAccountStatus != .available {
                clearSyncDataIfNeeded()
            }
        }
    }
    
    /// 是否启用同步（由用户控制）
    var isSyncEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(isSyncEnabled, forKey: "cloudkit_sync_enabled")
        }
    }
    
    /// 是否仅 WiFi 同步
    var wifiOnlySync: Bool = false {
        didSet {
            UserDefaults.standard.set(wifiOnlySync, forKey: "cloudkit_wifi_only")
        }
    }
    
    /// 待同步操作数量（估算）
    var pendingOperations: Int = 0
    
    /// 同步历史记录（最多保留20条）
    var syncHistory: [SyncEvent] = []
    
    /// 网络监控器
    let networkMonitor: NetworkMonitor
    
    /// CloudKit 容器
    private let container: CKContainer
    
    /// 对 SwiftData ModelContainer 的弱引用（用于手动触发同步）
    @ObservationIgnored
    weak var modelContainer: ModelContainer?
    
    /// 是否正在进行初始导入（重装后首次同步）
    var isPerformingInitialImport = false
    
    /// 存储最后一次导入/导出事件的时间，用于去重
    private var lastImportEventDate: Date?
    private var lastExportEventDate: Date?
    
    /// 缓存最近一次本地保存的变更计数（供 CloudKit 事件完成时使用）
    private var pendingExportCounts: (glucose: Int?, medication: Int?, meal: Int?)?
    
    // MARK: - Initialization
    
    init(networkMonitor: NetworkMonitor = NetworkMonitor()) {
        self.networkMonitor = networkMonitor
        self.container = CKContainer(identifier: AppConstants.cloudKitContainerID)
        
        // 读取用户偏好
        self.isSyncEnabled = UserDefaults.standard.bool(forKey: "cloudkit_sync_enabled")
        if UserDefaults.standard.object(forKey: "cloudkit_sync_enabled") == nil {
            self.isSyncEnabled = true // 默认启用
        }
        self.wifiOnlySync = UserDefaults.standard.bool(forKey: "cloudkit_wifi_only")
        
        // 加载最后同步时间
        if let savedDate = UserDefaults.standard.object(forKey: "cloudkit_last_sync_date") as? Date {
            self.lastSyncDate = savedDate
        }
        
        // 加载同步历史
        loadSyncHistory()
        
        // 检查账户状态
        Task {
            await checkAccountStatus()
        }
        
        // 监听同步事件
        setupNotifications()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    /// 检查 iCloud 账户状态
    @MainActor
    func checkAccountStatus() async {
        do {
            let status = try await container.accountStatus()
            iCloudAccountStatus = status
            
            #if DEBUG
            print("✅ iCloud 账户状态检查完成")
            switch status {
            case .available:
                print("   - 状态: 可用 ✓")
            case .noAccount:
                print("   - 状态: 未登录 iCloud 账户")
            case .restricted:
                print("   - 状态: 受限制（可能是家长控制）")
            case .couldNotDetermine:
                print("   - 状态: 无法确定")
            case .temporarilyUnavailable:
                print("   - 状态: 暂时不可用")
            @unknown default:
                print("   - 状态: 未知")
            }
            #endif
            
            // 如果账户可用，进行更详细的诊断
            if status == .available {
                await performCloudKitDiagnostics()
            }
        } catch {
            #if DEBUG
            print("❌ 检查 iCloud 账户状态失败: \(error)")
            #endif
            iCloudAccountStatus = .couldNotDetermine
        }
    }
    
    /// 执行 CloudKit 诊断
    private func performCloudKitDiagnostics() async {
        #if DEBUG
        let database = container.privateCloudDatabase
        
        // 测试基本的 CloudKit 连接
        print("🔍 正在测试 CloudKit 连接...")
        
        // 尝试获取用户记录
        do {
            let userRecordID = try await container.userRecordID()
            print("   ✓ 成功获取用户记录 ID: \(userRecordID.recordName)")
        } catch {
            print("   ⚠️ 获取用户记录 ID 失败: \(error.localizedDescription)")
        }
        
        // 检查默认 Zone（SwiftData 使用的 Zone）
        let defaultZoneID = CKRecordZone.ID(zoneName: "com.apple.coredata.cloudkit.zone", ownerName: CKCurrentUserDefaultName)
        
        do {
            let zone = try await database.recordZone(for: defaultZoneID)
            print("   ✓ CloudKit Zone 已存在: \(zone.zoneID.zoneName)")
        } catch let error as CKError {
            print("   ⚠️ CloudKit Zone 不存在或无法访问")
            print("      错误代码: \(error.errorCode)")
            print("      错误描述: \(error.localizedDescription)")
            
            // CKError Code 15 = ServerRejectedRequest
            // 这通常意味着 Zone 需要由 CoreData 首次创建
            if error.errorCode == 15 {
                print("      提示: 这是正常的首次启动行为，CoreData 会自动创建 Zone")
            }
        } catch {
            print("   ⚠️ 检查 Zone 时发生未知错误: \(error.localizedDescription)")
        }
        
        print("✅ CloudKit 诊断完成")
        #endif
    }
    
    /// 手动触发同步
    @MainActor
    func manualSync(modelContext: ModelContext? = nil) async throws {
        guard isSyncEnabled else {
            throw SyncError.syncDisabled
        }
        
        guard networkMonitor.isConnected else {
            throw SyncError.noNetwork
        }
        
        if wifiOnlySync && !networkMonitor.isUsingWiFi {
            throw SyncError.wifiRequired
        }
        
        guard iCloudAccountStatus == .available else {
            throw SyncError.accountNotAvailable
        }
        
        currentState = .syncing
        let syncStartDate = Date()
        
        // 1. 保存本地未提交的变更（触发上传）
        if let context = modelContext, context.hasChanges {
            do {
                try context.save()
                #if DEBUG
                print("✅ [手动同步] 已保存本地变更")
                #endif
            } catch {
                #if DEBUG
                print("⚠️ [手动同步] 保存变更失败: \(error)")
                #endif
            }
        }
        
        // 2. 触发 CoreData 底层持久化存储刷新，促使 NSPersistentCloudKitContainer 检查远程变化
        if let container = modelContainer {
            let bgContext = ModelContext(container)
            bgContext.autosaveEnabled = false
            // 执行一次 fetch 促使底层存储协调器与 CloudKit 交互
            let descriptor = FetchDescriptor<GlucoseRecord>(
                sortBy: [SortDescriptor(\GlucoseRecord.timestamp, order: .reverse)]
            )
            _ = try? bgContext.fetch(descriptor)
        }
        
        // 3. 等待足够时间让 CloudKit 同步响应（最多等待 10 秒，每秒检查一次）
        var receivedSyncEvent = false
        for _ in 0..<10 {
            try await Task.sleep(for: .seconds(1))
            
            let timeSinceImport = lastImportEventDate.map { syncStartDate.timeIntervalSince($0) } ?? 999
            let timeSinceExport = lastExportEventDate.map { syncStartDate.timeIntervalSince($0) } ?? 999
            
            if timeSinceImport <= 0 || timeSinceExport <= 0 {
                receivedSyncEvent = true
                break
            }
        }
        
        let now = Date()
        lastSyncDate = now
        
        if receivedSyncEvent {
            currentState = .success(now)
        } else {
            // 即使没收到同步事件，也标记为完成（可能没有新数据需要同步）
            currentState = .success(now)
        }
        
        let event = SyncEvent(
            type: .manualSync,
            isSuccess: true,
            glucoseCount: nil,
            medicationCount: nil,
            mealCount: nil
        )
        addSyncEvent(event)
        
        #if DEBUG
        print(receivedSyncEvent
              ? "✅ [手动同步] 检测到同步活动"
              : "ℹ️ [手动同步] 等待超时，可能没有新数据或同步仍在后台进行")
        #endif
        
        try? await Task.sleep(for: .seconds(2))
        if case .success(let date) = currentState, date == now {
            currentState = .idle
        }
    }
    
    /// 获取格式化的最后同步时间
    var lastSyncTimeString: String {
        guard let date = lastSyncDate else {
            return String(localized: "sync.never_synced")
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    /// 清除同步历史
    func clearSyncHistory() {
        syncHistory.removeAll()
        lastSyncDate = nil
        saveSyncHistory()
    }
    
    /// 当账户不可用时清除同步数据
    private func clearSyncDataIfNeeded() {
        // 只在账户明确不可用时清除，不确定状态不清除
        guard iCloudAccountStatus == .noAccount || 
              iCloudAccountStatus == .restricted else {
            return
        }
        
        // 清除同步相关数据
        syncHistory.removeAll()
        lastSyncDate = nil
        saveSyncHistory()
    }
    
    // MARK: - Private Methods
    
    /// 设置通知监听
    private func setupNotifications() {
        // 监听 SwiftData + CloudKit 的同步事件（从 iCloud 下载数据）
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleStoreRemoteChange(_:)),
            name: .NSPersistentStoreRemoteChange,
            object: nil
        )
        
        // 监听本地数据保存事件（可能上传到 iCloud）
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleContextDidSave(_:)),
            name: NSNotification.Name.NSManagedObjectContextDidSave,
            object: nil
        )
        
        // 监听 NSPersistentCloudKitContainer 同步事件（setup/import/export）
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCloudKitContainerEvent(_:)),
            name: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil
        )
    }
    
    /// 处理远程数据变化通知（从 iCloud 下载）
    @objc private func handleStoreRemoteChange(_ notification: Notification) {
        Task { @MainActor in
            // 只在同步启用且账户可用时记录
            guard isSyncEnabled,
                  iCloudAccountStatus == .available else {
                return
            }
            
            let now = Date()
            
            // 防止短时间内重复记录
            if let lastDate = lastImportEventDate, now.timeIntervalSince(lastDate) < 2 {
                return
            }
            
            lastImportEventDate = now
            lastSyncDate = now
            currentState = .success(now)
            
            // 统计变更数据
            let counts = extractChangeCounts(from: notification)
            
            let event = SyncEvent(
                type: .downloadFromCloud,
                isSuccess: true,
                glucoseCount: counts.glucose,
                medicationCount: counts.medication,
                mealCount: counts.meal
            )
            addSyncEvent(event)
            
            // 2秒后恢复为空闲状态
            try? await Task.sleep(for: .seconds(2))
            if case .success(let date) = currentState, date == now {
                currentState = .idle
            }
        }
    }
    
    /// 处理本地上下文保存通知
    /// 仅缓存变更计数，不记录同步事件（实际上传结果由 handleCloudKitContainerEvent 负责）
    @objc private func handleContextDidSave(_ notification: Notification) {
        Task { @MainActor in
            guard isSyncEnabled,
                  networkMonitor.isConnected,
                  iCloudAccountStatus == .available else {
                return
            }
            
            let counts = extractChangeCounts(from: notification)
            guard counts.total > 0 else { return }
            
            // 缓存变更计数，供 CloudKit export 完成事件使用
            pendingExportCounts = (glucose: counts.glucose, medication: counts.medication, meal: counts.meal)
        }
    }
    
    /// 处理 NSPersistentCloudKitContainer 同步事件
    @objc private func handleCloudKitContainerEvent(_ notification: Notification) {
        guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                as? NSPersistentCloudKitContainer.Event else {
            return
        }
        
        Task { @MainActor in
            let typeStr: String
            switch event.type {
            case .setup:
                typeStr = "Setup"
            case .import:
                typeStr = "Import"
                if event.endDate == nil {
                    currentState = .importing
                    isPerformingInitialImport = true
                }
            case .export:
                typeStr = "Export"
                if event.endDate == nil {
                    currentState = .exporting
                }
            @unknown default:
                typeStr = "Unknown"
            }
            
            if let endDate = event.endDate {
                // 事件已完成
                if event.succeeded {
                    #if DEBUG
                    print("✅ [CloudKit \(typeStr)] 完成")
                    #endif
                    
                    let eventType: SyncEvent.EventType
                    if event.type == .import {
                        lastImportEventDate = endDate
                        isPerformingInitialImport = false
                        eventType = .downloadFromCloud
                    } else {
                        lastExportEventDate = endDate
                        eventType = .uploadToCloud
                    }
                    
                    lastSyncDate = endDate
                    currentState = .success(endDate)
                    
                    // 记录成功的同步事件，附带缓存的变更计数
                    if event.type == .export, let counts = pendingExportCounts {
                        let syncEvent = SyncEvent(
                            type: eventType,
                            isSuccess: true,
                            glucoseCount: counts.glucose,
                            medicationCount: counts.medication,
                            mealCount: counts.meal
                        )
                        addSyncEvent(syncEvent)
                        pendingExportCounts = nil
                    } else if event.type == .import {
                        let syncEvent = SyncEvent(
                            type: eventType,
                            isSuccess: true
                        )
                        addSyncEvent(syncEvent)
                    }
                    
                    // 2秒后恢复为空闲
                    let successDate = endDate
                    try? await Task.sleep(for: .seconds(2))
                    if case .success(let d) = currentState, d == successDate {
                        currentState = .idle
                    }
                } else if let error = event.error {
                    #if DEBUG
                    print("❌ [CloudKit \(typeStr)] 失败: \(error.localizedDescription)")
                    if let ckError = error as? CKError {
                        if ckError.code == .quotaExceeded {
                            let retryStr = ckError.retryAfterSeconds.map { "\($0)秒后重试" } ?? ""
                            print("   ⚠️ iCloud 存储空间不足 \(retryStr)")
                            print("   💡 请前往「设置 > Apple ID > iCloud」管理存储空间")
                        }
                    }
                    #endif
                    
                    if event.type == .import {
                        isPerformingInitialImport = false
                    }
                    
                    currentState = .failed(error)
                    pendingExportCounts = nil
                    
                    // 将 CKError 转换为更友好的错误消息
                    let friendlyMessage = friendlyErrorMessage(for: error)
                    
                    let syncEvent = SyncEvent(
                        type: event.type == .import ? .downloadFromCloud : .uploadToCloud,
                        isSuccess: false,
                        errorMessage: friendlyMessage
                    )
                    addSyncEvent(syncEvent)
                }
            } else {
                #if DEBUG
                print("🔄 [CloudKit \(typeStr)] 进行中...")
                #endif
            }
        }
    }
    
    /// 将 CloudKit/网络错误转换为用户友好的消息
    private func friendlyErrorMessage(for error: Error) -> String {
        if let ckError = error as? CKError {
            switch ckError.code {
            case .networkUnavailable:
                return "网络不可用，将自动重试"
            case .networkFailure:
                return "网络连接失败，将自动重试"
            case .serviceUnavailable:
                return "iCloud 服务暂时不可用，将自动重试"
            case .requestRateLimited:
                if let retryAfter = ckError.retryAfterSeconds {
                    let minutes = Int(ceil(retryAfter / 60))
                    return "请求过于频繁，\(minutes)分钟后自动重试"
                }
                return "请求过于频繁，稍后自动重试"
            case .zoneBusy:
                return "iCloud 繁忙，稍后自动重试"
            case .quotaExceeded:
                if let retryAfter = ckError.retryAfterSeconds {
                    let minutes = Int(ceil(retryAfter / 60))
                    return "iCloud 存储空间不足，\(minutes)分钟后重试"
                }
                return "iCloud 存储空间不足"
            case .notAuthenticated:
                return "iCloud 未登录"
            default:
                return "同步错误 (CKError \(ckError.code.rawValue))"
            }
        }
        
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case -1009:
                return "网络连接已断开，将自动重试"
            case -1001:
                return "请求超时，将自动重试"
            default:
                return "网络错误，将自动重试"
            }
        }
        
        return error.localizedDescription
    }
    
    /// 从通知中提取变更数据统计
    private func extractChangeCounts(from notification: Notification) -> (glucose: Int?, medication: Int?, meal: Int?, total: Int) {
        guard let userInfo = notification.userInfo else {
            return (nil, nil, nil, 0)
        }
        
        var glucoseCount = 0
        var medicationCount = 0
        var mealCount = 0
        
        // 合并插入、更新、删除的对象
        let keys = [
            NSInsertedObjectsKey,
            NSUpdatedObjectsKey,
            NSDeletedObjectsKey
        ]
        
        for key in keys {
            guard let objects = userInfo[key] as? Set<NSManagedObject> else { continue }
            
            for object in objects {
                let entityName = object.entity.name ?? ""
                
                switch entityName {
                case "GlucoseRecord":
                    glucoseCount += 1
                case "MedicationRecord":
                    medicationCount += 1
                case "MealRecord":
                    mealCount += 1
                default:
                    break
                }
            }
        }
        
        let total = glucoseCount + medicationCount + mealCount
        
        return (
            glucose: glucoseCount > 0 ? glucoseCount : nil,
            medication: medicationCount > 0 ? medicationCount : nil,
            meal: mealCount > 0 ? mealCount : nil,
            total: total
        )
    }
    
    /// 添加同步事件到历史
    private func addSyncEvent(_ event: SyncEvent) {
        syncHistory.insert(event, at: 0)
        
        // 只保留最近20条
        if syncHistory.count > 20 {
            syncHistory = Array(syncHistory.prefix(20))
        }
        
        saveSyncHistory()
    }
    
    /// 保存同步历史
    private func saveSyncHistory() {
        if let encoded = try? JSONEncoder().encode(syncHistory) {
            UserDefaults.standard.set(encoded, forKey: "cloudkit_sync_history")
        }
    }
    
    /// 加载同步历史
    private func loadSyncHistory() {
        if let data = UserDefaults.standard.data(forKey: "cloudkit_sync_history"),
           let decoded = try? JSONDecoder().decode([SyncEvent].self, from: data) {
            syncHistory = decoded
        }
    }
}

// MARK: - Sync Errors

enum SyncError: LocalizedError {
    case syncDisabled
    case noNetwork
    case wifiRequired
    case accountNotAvailable
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .syncDisabled:
            return "同步已禁用"
        case .noNetwork:
            return "无网络连接"
        case .wifiRequired:
            return "需要 WiFi 连接"
        case .accountNotAvailable:
            return "iCloud 账户不可用"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
