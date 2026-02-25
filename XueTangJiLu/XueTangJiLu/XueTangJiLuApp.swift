//
//  XueTangJiLuApp.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import SwiftUI
import SwiftData

@main
struct XueTangJiLuApp: App {
    let modelContainer: ModelContainer
    let healthKitManager = HealthKitManager()
    let cloudKitSyncManager = CloudKitSyncManager()
    let deduplicationService = DataDeduplicationService()

    init() {
        let schema = Schema([
            GlucoseRecord.self,
            UserSettings.self,
            MedicationRecord.self,
            MealRecord.self,
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(AppConstants.appGroupID),
            cloudKitDatabase: .private(AppConstants.cloudKitContainerID)
        )

        do {
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("无法创建 ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(healthKitManager)
                .environment(cloudKitSyncManager)
                .task {
                    // 应用启动时执行一次去重
                    let context = ModelContext(modelContainer)
                    try? await deduplicationService.deduplicateAll(context: context)
                }
        }
        .modelContainer(modelContainer)
    }
}
