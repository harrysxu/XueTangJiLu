//
//  MainTabView.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import SwiftUI

/// 底部 Tab 导航容器
struct MainTabView: View {
    @State private var selectedTab: Tab = .home

    enum Tab: String {
        case home = "记录"
        case trend = "趋势"
        case settings = "设置"
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label(Tab.home.rawValue, systemImage: selectedTab == .home ? "list.bullet" : "list.bullet")
                }
                .tag(Tab.home)

            TrendView()
                .tabItem {
                    Label(Tab.trend.rawValue, systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(Tab.trend)

            SettingsView()
                .tabItem {
                    Label(Tab.settings.rawValue, systemImage: selectedTab == .settings ? "gearshape.fill" : "gearshape")
                }
                .tag(Tab.settings)
        }
        .tint(Color.brandPrimary)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [GlucoseRecord.self, UserSettings.self], inMemory: true)
        .environment(HealthKitManager())
}
