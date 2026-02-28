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
    
    /// 变更计数（区分新增/更新和删除）
    struct ChangeCounts {
        var glucose: Int = 0
        var medication: Int = 0
        var meal: Int = 0
        var deletedGlucose: Int = 0
        var deletedMedication: Int = 0
        var deletedMeal: Int = 0
        
        var syncedTotal: Int { glucose + medication + meal }
        var deletedTotal: Int { deletedGlucose + deletedMedication + deletedMeal }
        var total: Int { syncedTotal + deletedTotal }
        var isEmpty: Bool { total == 0 }
        
        mutating func merge(_ other: ChangeCounts) {
            glucose += other.glucose
            medication += other.medication
            meal += other.meal
            deletedGlucose += other.deletedGlucose
            deletedMedication += other.deletedMedication
            deletedMeal += other.deletedMeal
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
        
        let deletedGlucoseCount: Int?
        let deletedMedicationCount: Int?
        let deletedMealCount: Int?
        
        enum EventType: String, Codable {
            case downloadFromCloud = "download"
            case uploadToCloud = "upload"
            case setup = "setup"
            case manualSync = "manual"
            
            var localizedString: String {
                switch self {
                case .downloadFromCloud:
                    return String(localized: "sync.event.download")
                case .uploadToCloud:
                    return String(localized: "sync.event.upload")
                case .setup:
                    return String(localized: "sync.event.setup")
                case .manualSync:
                    return String(localized: "sync.event.manual_sync")
                }
            }
        }
        
        init(type: EventType,
             isSuccess: Bool,
             errorMessage: String? = nil,
             glucoseCount: Int? = nil,
             medicationCount: Int? = nil,
             mealCount: Int? = nil,
             deletedGlucoseCount: Int? = nil,
             deletedMedicationCount: Int? = nil,
             deletedMealCount: Int? = nil) {
            self.id = UUID()
            self.timestamp = Date()
            self.type = type
            self.isSuccess = isSuccess
            self.errorMessage = errorMessage
            self.glucoseCount = glucoseCount
            self.medicationCount = medicationCount
            self.mealCount = mealCount
            self.deletedGlucoseCount = deletedGlucoseCount
            self.deletedMedicationCount = deletedMedicationCount
            self.deletedMealCount = deletedMealCount
        }
        
        var totalCount: Int {
            (glucoseCount ?? 0) + (medicationCount ?? 0) + (mealCount ?? 0)
        }
        
        var totalDeletedCount: Int {
            (deletedGlucoseCount ?? 0) + (deletedMedicationCount ?? 0) + (deletedMealCount ?? 0)
        }
        
        var hasCountData: Bool {
            totalCount > 0 || totalDeletedCount > 0
        }
        
        func formattedCountString() -> String? {
            var parts: [String] = []
            
            if let count = glucoseCount, count > 0 {
                parts.append(String(format: NSLocalizedString("sync.count.glucose", comment: ""), count))
            }
            if let count = medicationCount, count > 0 {
                parts.append(String(format: NSLocalizedString("sync.count.medication", comment: ""), count))
            }
            if let count = mealCount, count > 0 {
                parts.append(String(format: NSLocalizedString("sync.count.meal", comment: ""), count))
            }
            
            guard !parts.isEmpty else { return nil }
            return parts.joined(separator: "，")
        }
        
        func formattedDeletedCountString() -> String? {
            var parts: [String] = []
            
            if let count = deletedGlucoseCount, count > 0 {
                parts.append(String(format: NSLocalizedString("sync.count.deleted_glucose", comment: ""), count))
            }
            if let count = deletedMedicationCount, count > 0 {
                parts.append(String(format: NSLocalizedString("sync.count.deleted_medication", comment: ""), count))
            }
            if let count = deletedMealCount, count > 0 {
                parts.append(String(format: NSLocalizedString("sync.count.deleted_meal", comment: ""), count))
            }
            
            guard !parts.isEmpty else { return nil }
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
    
    /// iCloud 存储配额是否超限（供 UI 显示引导）
    var isQuotaExceeded: Bool = false
    
    /// 是否有待同步的变更
    var hasPendingChanges: Bool = false
    
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
    
    /// 缓存本地保存的变更计数（供 CloudKit export 事件完成时使用）
    private var pendingExportCounts: ChangeCounts?
    
    /// 缓存远程导入的变更计数（供 CloudKit import 事件完成时使用）
    private var pendingImportCounts: ChangeCounts?
    
    /// CloudKit 容器事件级别的导入标记，用于准确区分 import/export 上下文
    private var isImporting = false
    
    /// import 开始前的记录快照（用于通过前后差值计算导入数量）
    private var preImportRecordCounts: (glucose: Int, medication: Int, meal: Int)?
    
    /// 手动同步期间的状态与累计计数
    private var isManualSyncing = false
    private var manualSyncCounts = ChangeCounts()
    
    // MARK: - Initialization
    
    init(networkMonitor: NetworkMonitor = NetworkMonitor()) {
        self.networkMonitor = networkMonitor
        self.container = CKContainer(identifier: AppConstants.cloudKitContainerID)
        
        self.isSyncEnabled = UserDefaults.standard.bool(forKey: "cloudkit_sync_enabled")
        if UserDefaults.standard.object(forKey: "cloudkit_sync_enabled") == nil {
            self.isSyncEnabled = true
        }
        self.wifiOnlySync = UserDefaults.standard.bool(forKey: "cloudkit_wifi_only")
        
        if let savedDate = UserDefaults.standard.object(forKey: "cloudkit_last_sync_date") as? Date {
            self.lastSyncDate = savedDate
        }
        
        loadSyncHistory()
        
        Task {
            await checkAccountStatus()
        }
        
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
        
        print("🔍 正在测试 CloudKit 连接...")
        
        do {
            let userRecordID = try await container.userRecordID()
            print("   ✓ 成功获取用户记录 ID: \(userRecordID.recordName)")
        } catch {
            print("   ⚠️ 获取用户记录 ID 失败: \(error.localizedDescription)")
        }
        
        let defaultZoneID = CKRecordZone.ID(zoneName: "com.apple.coredata.cloudkit.zone", ownerName: CKCurrentUserDefaultName)
        
        do {
            let zone = try await database.recordZone(for: defaultZoneID)
            print("   ✓ CloudKit Zone 已存在: \(zone.zoneID.zoneName)")
        } catch let error as CKError {
            print("   ⚠️ CloudKit Zone 不存在或无法访问")
            print("      错误代码: \(error.errorCode)")
            print("      错误描述: \(error.localizedDescription)")
            
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
        
        isManualSyncing = true
        manualSyncCounts = ChangeCounts()
        
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
        
        if let container = modelContainer {
            let bgContext = ModelContext(container)
            bgContext.autosaveEnabled = false
            let descriptor = FetchDescriptor<GlucoseRecord>(
                sortBy: [SortDescriptor(\GlucoseRecord.timestamp, order: .reverse)]
            )
            _ = try? bgContext.fetch(descriptor)
        }
        
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
        isManualSyncing = false
        currentState = .success(now)
        
        if !manualSyncCounts.isEmpty {
            let counts = manualSyncCounts
            let event = SyncEvent(
                type: .manualSync,
                isSuccess: true,
                glucoseCount: counts.glucose > 0 ? counts.glucose : nil,
                medicationCount: counts.medication > 0 ? counts.medication : nil,
                mealCount: counts.meal > 0 ? counts.meal : nil,
                deletedGlucoseCount: counts.deletedGlucose > 0 ? counts.deletedGlucose : nil,
                deletedMedicationCount: counts.deletedMedication > 0 ? counts.deletedMedication : nil,
                deletedMealCount: counts.deletedMeal > 0 ? counts.deletedMeal : nil
            )
            addSyncEvent(event)
        }
        manualSyncCounts = ChangeCounts()
        
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
    
    /// 等待 CloudKit export 完成（用于删除后确保数据同步到 iCloud）
    @MainActor
    func waitForExportCompletion(timeout: TimeInterval = 15) async -> Bool {
        let startDate = Date()
        let checkIntervalMs = 500
        let maxChecks = Int(timeout * 1000) / checkIntervalMs
        
        for _ in 0..<maxChecks {
            try? await Task.sleep(for: .milliseconds(checkIntervalMs))
            
            if let lastExport = lastExportEventDate, lastExport > startDate {
                return true
            }
        }
        
        return false
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
        guard iCloudAccountStatus == .noAccount ||
              iCloudAccountStatus == .restricted else {
            return
        }
        
        syncHistory.removeAll()
        lastSyncDate = nil
        saveSyncHistory()
    }
    
    // MARK: - Private Methods
    
    /// 设置通知监听
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleStoreRemoteChange(_:)),
            name: .NSPersistentStoreRemoteChange,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleContextDidSave(_:)),
            name: NSNotification.Name.NSManagedObjectContextDidSave,
            object: nil
        )
        
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
            guard isSyncEnabled,
                  iCloudAccountStatus == .available else {
                return
            }
            
            let now = Date()
            
            if let lastDate = lastImportEventDate, now.timeIntervalSince(lastDate) < 2 {
                return
            }
            
            lastImportEventDate = now
            lastSyncDate = now
            currentState = .success(now)
            
            try? await Task.sleep(for: .seconds(2))
            if case .success(let date) = currentState, date == now {
                currentState = .idle
            }
        }
    }
    
    /// 处理本地上下文保存通知
    /// 根据 isImporting 标记准确分类：import 事件期间的保存归为导入计数，否则归为导出计数
    @objc private func handleContextDidSave(_ notification: Notification) {
        let counts = extractChangeCounts(from: notification)
        guard !counts.isEmpty else { return }
        
        Task { @MainActor in
            guard isSyncEnabled,
                  networkMonitor.isConnected,
                  iCloudAccountStatus == .available else {
                return
            }
            
            if isImporting {
                if var existing = pendingImportCounts {
                    existing.merge(counts)
                    pendingImportCounts = existing
                } else {
                    pendingImportCounts = counts
                }
            } else {
                if var existing = pendingExportCounts {
                    existing.merge(counts)
                    pendingExportCounts = existing
                } else {
                    pendingExportCounts = counts
                }
                hasPendingChanges = true
            }
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
                    isImporting = true
                    preImportRecordCounts = countCurrentRecords()
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
                if event.succeeded {
                    #if DEBUG
                    print("✅ [CloudKit \(typeStr)] 完成")
                    #endif
                    
                    isQuotaExceeded = false
                    
                    switch event.type {
                    case .setup:
                        break
                        
                    case .import:
                        lastImportEventDate = endDate
                        isPerformingInitialImport = false
                        isImporting = false
                        lastSyncDate = endDate
                        currentState = .success(endDate)
                        
                        var importCounts = pendingImportCounts ?? ChangeCounts()
                        
                        if importCounts.syncedTotal == 0 && importCounts.deletedTotal == 0,
                           let preCounts = preImportRecordCounts {
                            let postCounts = countCurrentRecords()
                            let gDelta = postCounts.glucose - preCounts.glucose
                            let mDelta = postCounts.medication - preCounts.medication
                            let mealDelta = postCounts.meal - preCounts.meal
                            if gDelta > 0 { importCounts.glucose = gDelta }
                            if gDelta < 0 { importCounts.deletedGlucose = -gDelta }
                            if mDelta > 0 { importCounts.medication = mDelta }
                            if mDelta < 0 { importCounts.deletedMedication = -mDelta }
                            if mealDelta > 0 { importCounts.meal = mealDelta }
                            if mealDelta < 0 { importCounts.deletedMeal = -mealDelta }
                        }
                        
                        if isManualSyncing {
                            manualSyncCounts.merge(importCounts)
                        } else if !importCounts.isEmpty {
                            let syncEvent = SyncEvent(
                                type: .downloadFromCloud,
                                isSuccess: true,
                                glucoseCount: importCounts.glucose > 0 ? importCounts.glucose : nil,
                                medicationCount: importCounts.medication > 0 ? importCounts.medication : nil,
                                mealCount: importCounts.meal > 0 ? importCounts.meal : nil,
                                deletedGlucoseCount: importCounts.deletedGlucose > 0 ? importCounts.deletedGlucose : nil,
                                deletedMedicationCount: importCounts.deletedMedication > 0 ? importCounts.deletedMedication : nil,
                                deletedMealCount: importCounts.deletedMeal > 0 ? importCounts.deletedMeal : nil
                            )
                            addSyncEvent(syncEvent)
                        }
                        pendingImportCounts = nil
                        preImportRecordCounts = nil
                        
                    case .export:
                        lastExportEventDate = endDate
                        lastSyncDate = endDate
                        currentState = .success(endDate)
                        hasPendingChanges = false
                        
                        let exportCounts = pendingExportCounts ?? ChangeCounts()
                        
                        if isManualSyncing {
                            manualSyncCounts.merge(exportCounts)
                        } else if !exportCounts.isEmpty {
                            let syncEvent = SyncEvent(
                                type: .uploadToCloud,
                                isSuccess: true,
                                glucoseCount: exportCounts.glucose > 0 ? exportCounts.glucose : nil,
                                medicationCount: exportCounts.medication > 0 ? exportCounts.medication : nil,
                                mealCount: exportCounts.meal > 0 ? exportCounts.meal : nil,
                                deletedGlucoseCount: exportCounts.deletedGlucose > 0 ? exportCounts.deletedGlucose : nil,
                                deletedMedicationCount: exportCounts.deletedMedication > 0 ? exportCounts.deletedMedication : nil,
                                deletedMealCount: exportCounts.deletedMeal > 0 ? exportCounts.deletedMeal : nil
                            )
                            addSyncEvent(syncEvent)
                        }
                        pendingExportCounts = nil
                        
                    @unknown default:
                        break
                    }
                    
                    if event.type != .setup {
                        let successDate = endDate
                        try? await Task.sleep(for: .seconds(2))
                        if case .success(let d) = currentState, d == successDate {
                            currentState = .idle
                        }
                    }
                } else if let error = event.error {
                    guard event.type != .setup else {
                        #if DEBUG
                        print("⚠️ [CloudKit Setup] 失败: \(error.localizedDescription)")
                        #endif
                        return
                    }
                    
                    let quotaHit = isQuotaExceededError(error)
                    
                    #if DEBUG
                    print("❌ [CloudKit \(typeStr)] 失败: \(error.localizedDescription)")
                    if quotaHit {
                        print("   ⚠️ iCloud 存储空间不足")
                        print("   💡 请前往「设置 > Apple ID > iCloud」管理存储空间")
                    }
                    #endif
                    
                    if event.type == .import {
                        isPerformingInitialImport = false
                        isImporting = false
                    }
                    
                    isQuotaExceeded = quotaHit
                    currentState = .failed(error)
                    pendingExportCounts = nil
                    pendingImportCounts = nil
                    
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
    
    /// 检测错误是否包含 quotaExceeded（支持 Partial Failure 解包）
    private func isQuotaExceededError(_ error: Error) -> Bool {
        guard let ckError = error as? CKError else { return false }
        if ckError.code == .quotaExceeded { return true }
        if ckError.code == .partialFailure,
           let partialErrors = ckError.partialErrorsByItemID {
            return partialErrors.values.contains { partialError in
                (partialError as? CKError)?.code == .quotaExceeded
            }
        }
        return false
    }
    
    /// 将 CloudKit/网络错误转换为用户友好的消息
    private func friendlyErrorMessage(for error: Error) -> String {
        if isQuotaExceededError(error) {
            return String(localized: "sync.error.quota_exceeded",
                          defaultValue: "iCloud 存储空间不足，请前往「设置 > Apple ID > iCloud」管理存储空间")
        }
        
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
                return String(localized: "sync.error.quota_exceeded",
                              defaultValue: "iCloud 存储空间不足，请前往「设置 > Apple ID > iCloud」管理存储空间")
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
    
    /// 从通知中提取变更数据统计（区分新增/更新和删除）
    private func extractChangeCounts(from notification: Notification) -> ChangeCounts {
        guard let userInfo = notification.userInfo else {
            return ChangeCounts()
        }
        
        var counts = ChangeCounts()
        
        let addKeys = [NSInsertedObjectsKey, NSUpdatedObjectsKey]
        for key in addKeys {
            guard let objects = userInfo[key] as? Set<NSManagedObject> else { continue }
            for object in objects {
                let entityName = object.entity.name ?? ""
                switch entityName {
                case "GlucoseRecord": counts.glucose += 1
                case "MedicationRecord": counts.medication += 1
                case "MealRecord": counts.meal += 1
                default: break
                }
            }
        }
        
        if let deletedObjects = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject> {
            for object in deletedObjects {
                let entityName = object.entity.name ?? ""
                switch entityName {
                case "GlucoseRecord": counts.deletedGlucose += 1
                case "MedicationRecord": counts.deletedMedication += 1
                case "MealRecord": counts.deletedMeal += 1
                default: break
                }
            }
        }
        
        return counts
    }
    
    /// 快照当前数据库中各类记录数量（用于 import 前后对比）
    @MainActor
    private func countCurrentRecords() -> (glucose: Int, medication: Int, meal: Int) {
        guard let container = modelContainer else { return (0, 0, 0) }
        let context = ModelContext(container)
        context.autosaveEnabled = false
        do {
            let glucose = try context.fetchCount(FetchDescriptor<GlucoseRecord>())
            let medication = try context.fetchCount(FetchDescriptor<MedicationRecord>())
            let meal = try context.fetchCount(FetchDescriptor<MealRecord>())
            return (glucose, medication, meal)
        } catch {
            #if DEBUG
            print("⚠️ [同步] 统计记录数量失败: \(error)")
            #endif
            return (0, 0, 0)
        }
    }
    
    /// 添加同步事件到历史
    private func addSyncEvent(_ event: SyncEvent) {
        syncHistory.insert(event, at: 0)
        
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
