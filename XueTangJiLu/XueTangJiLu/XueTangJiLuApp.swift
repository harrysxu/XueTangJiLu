//
//  XueTangJiLuApp.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import SwiftUI
import SwiftData
import UserNotifications
import CoreData

@main
struct XueTangJiLuApp: App {
    let modelContainer: ModelContainer
    let healthKitManager = HealthKitManager()
    let cloudKitSyncManager = CloudKitSyncManager()
    let deduplicationService = DataDeduplicationService()
    let storeManager = StoreManager()
    let subscriptionManager = SubscriptionManager()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // 1. 读取用户的同步设置
        let syncEnabled = UserDefaults.standard.object(forKey: "cloudkit_sync_enabled") as? Bool ?? true
        
        #if DEBUG
        print("📱 应用启动 - iCloud 同步状态: \(syncEnabled ? "已启用" : "已禁用")")
        #endif
        
        // 2. 如果启用同步，先尝试手动初始化 CloudKit
        if syncEnabled {
            Task {
                let initializer = CloudKitInitializer(
                    containerIdentifier: AppConstants.cloudKitContainerID
                )
                await initializer.initializeCloudKit()
            }
        }
        
        // 3. 创建 ModelContainer（使用迁移计划）
        let modelConfiguration = ModelConfiguration(
            schema: Schema([
                UserSettings.self,
                GlucoseRecord.self,
                MedicationRecord.self,
                MealRecord.self
            ]),
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(AppConstants.appGroupID),
            // ⚠️ 关键：根据用户设置决定是否启用 CloudKit
            cloudKitDatabase: syncEnabled ? .private(AppConstants.cloudKitContainerID) : .none
        )

        do {
            modelContainer = try ModelContainer(
                for: UserSettings.self,
                GlucoseRecord.self,
                MedicationRecord.self,
                MealRecord.self,
                migrationPlan: XueTangJiLuMigrationPlan.self,
                configurations: modelConfiguration
            )
            
            // 将 ModelContainer 传递给同步管理器，用于手动同步
            cloudKitSyncManager.modelContainer = modelContainer
            
            if syncEnabled {
                print("✅ ModelContainer 创建成功，CloudKit 同步已配置")
                print("   - Container ID: \(AppConstants.cloudKitContainerID)")
                print("   - App Group: \(AppConstants.appGroupID)")
            } else {
                print("✅ ModelContainer 创建成功，CloudKit 同步已禁用")
                print("   - 仅使用本地存储")
                print("   - App Group: \(AppConstants.appGroupID)")
            }
        } catch {
            fatalError("无法创建 ModelContainer: \(error)")
        }
    }

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(healthKitManager)
                .environment(cloudKitSyncManager)
                .environment(storeManager)
                .environment(subscriptionManager)
                .task {
                    try? await Task.sleep(for: .seconds(5))
                    let context = modelContainer.mainContext
                    try? deduplicationService.deduplicateUserSettings(context: context)
                    subscriptionManager.updateSubscriptionStatus(from: storeManager)
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        Task {
                            await storeManager.updatePurchasedProducts()
                            subscriptionManager.updateSubscriptionStatus(from: storeManager)
                        }
                    }
                }
        }
        .modelContainer(modelContainer)
    }
}

// MARK: - AppDelegate for Notification Handling

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        
        // 注册远程通知 — CloudKit 同步依赖静默推送来感知云端数据变化
        application.registerForRemoteNotifications()
        
        return true
    }
    
    // MARK: - Remote Notification Registration
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        #if DEBUG
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        print("✅ 远程通知注册成功, token: \(token.prefix(16))...")
        #endif
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        #if DEBUG
        print("❌ 远程通知注册失败: \(error.localizedDescription)")
        #endif
    }
    
    // MARK: - Remote Notification Handling (CloudKit Sync)
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        #if DEBUG
        print("📬 收到 CloudKit 远程通知，将触发数据同步")
        #endif
        // NSPersistentCloudKitContainer 会自动处理 CloudKit 推送并同步数据
        completionHandler(.newData)
    }
    
    // MARK: - UNUserNotificationCenter Delegate
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}
