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

/// CloudKit 同步管理器
@Observable
final class CloudKitSyncManager {
    
    // MARK: - Types
    
    /// 同步状态
    enum SyncState: Equatable {
        case idle
        case syncing
        case success(Date)
        case failed(Error)
        
        static func == (lhs: SyncState, rhs: SyncState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.syncing, .syncing):
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
        
        enum EventType: String, Codable {
            case importData = "导入"
            case exportData = "导出"
            case setup = "初始化"
        }
        
        init(type: EventType, isSuccess: Bool, errorMessage: String? = nil) {
            self.id = UUID()
            self.timestamp = Date()
            self.type = type
            self.isSuccess = isSuccess
            self.errorMessage = errorMessage
        }
    }
    
    // MARK: - Properties
    
    /// 当前同步状态
    var currentState: SyncState = .idle
    
    /// 最后同步时间
    var lastSyncDate: Date?
    
    /// iCloud 账户状态
    var iCloudAccountStatus: CKAccountStatus = .couldNotDetermine
    
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
    
    /// 存储最后一次导入/导出事件的时间，用于去重
    private var lastImportEventDate: Date?
    private var lastExportEventDate: Date?
    
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
        } catch {
            print("检查 iCloud 账户状态失败: \(error)")
            iCloudAccountStatus = .couldNotDetermine
        }
    }
    
    /// 手动触发同步
    @MainActor
    func manualSync() async throws {
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
        
        // SwiftData + CloudKit 会自动同步，这里只是触发状态更新
        // 实际的同步由 NSPersistentCloudKitContainer 处理
        
        // 等待一小段时间，让系统有机会触发同步
        try await Task.sleep(for: .seconds(1))
        
        // 注意：实际同步完成会通过通知回调更新状态
    }
    
    /// 获取格式化的最后同步时间
    var lastSyncTimeString: String {
        guard let date = lastSyncDate else {
            return "从未同步"
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    /// 清除同步历史
    func clearSyncHistory() {
        syncHistory.removeAll()
        saveSyncHistory()
    }
    
    // MARK: - Private Methods
    
    /// 设置通知监听
    private func setupNotifications() {
        // 监听 SwiftData + CloudKit 的同步事件
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleStoreRemoteChange(_:)),
            name: .NSPersistentStoreRemoteChange,
            object: nil
        )
        
        // 如果使用 NSPersistentCloudKitContainer，还需要监听其事件
        // 注意：SwiftData 使用的是类似机制，但事件名可能不同
        
        // 监听网络状态变化
        // NetworkMonitor 已经是 @Observable，会自动更新
    }
    
    /// 处理远程数据变化通知
    @objc private func handleStoreRemoteChange(_ notification: Notification) {
        Task { @MainActor in
            // 远程数据有更新，记录为导入事件
            let now = Date()
            
            // 防止短时间内重复记录
            if let lastDate = lastImportEventDate, now.timeIntervalSince(lastDate) < 2 {
                return
            }
            
            lastImportEventDate = now
            lastSyncDate = now
            currentState = .success(now)
            
            let event = SyncEvent(type: .importData, isSuccess: true)
            addSyncEvent(event)
            
            // 2秒后恢复为空闲状态
            try? await Task.sleep(for: .seconds(2))
            if case .success(let date) = currentState, date == now {
                currentState = .idle
            }
        }
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
