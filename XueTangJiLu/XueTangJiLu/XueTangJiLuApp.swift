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

    init() {
        let schema = Schema([
            GlucoseRecord.self,
            UserSettings.self,
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
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
        }
        .modelContainer(modelContainer)
    }
}
