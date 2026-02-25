//
//  ContentView.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import SwiftUI
import SwiftData

/// 根视图：根据是否完成引导决定显示引导页或主页
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsArray: [UserSettings]

    /// 获取或创建用户设置（含 iCloud 同步去重）
    private var settings: UserSettings {
        // 如果有多份设置（iCloud 同步导致），执行去重合并
        if settingsArray.count > 1 {
            let result = UserSettings.deduplicate(settingsArray)
            for dup in result.toDelete {
                modelContext.delete(dup)
            }
            return result.keep
        }

        if let existing = settingsArray.first {
            // 初始化本地化的默认标签（仅在首次启动时执行一次）
            existing.initializeLocalizedDefaultTagsIfNeeded()
            return existing
        }
        let newSettings = UserSettings()
        modelContext.insert(newSettings)
        // 初始化本地化的默认标签
        newSettings.initializeLocalizedDefaultTagsIfNeeded()
        return newSettings
    }

    var body: some View {
        Group {
            if settings.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [GlucoseRecord.self, UserSettings.self, MedicationRecord.self], inMemory: true)
        .environment(HealthKitManager())
}
