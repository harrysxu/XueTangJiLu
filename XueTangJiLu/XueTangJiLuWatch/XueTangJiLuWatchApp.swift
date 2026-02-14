//
//  XueTangJiLuWatchApp.swift
//  XueTangJiLuWatch
//
//  Created by AI Assistant on 2026/2/14.
//

import SwiftUI
import SwiftData

/// Apple Watch 应用入口
/// 注意：需要在 Xcode 中创建 Watch App target 并添加此文件
/// 步骤：File → New → Target → watchOS → App
@main
struct XueTangJiLuWatchApp: App {
    let modelContainer: ModelContainer

    init() {
        let schema = Schema([GlucoseRecord.self, UserSettings.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(AppConstants.appGroupID)
        )

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Watch ModelContainer 创建失败: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            WatchHomeView()
        }
        .modelContainer(modelContainer)
    }
}
