//
//  MainTabView.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import SwiftUI
import SwiftData

/// 底部 Tab 导航容器
struct MainTabView: View {
    @State private var selectedTab: Tab = .dashboard

    enum Tab: String {
        case dashboard = "首页"
        case log = "记录"
        case insights = "洞察"
        case profile = "我的"
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label(Tab.dashboard.rawValue, systemImage: selectedTab == .dashboard ? "house.fill" : "house")
                }
                .tag(Tab.dashboard)

            LogView()
                .tabItem {
                    Label(Tab.log.rawValue, systemImage: selectedTab == .log ? "square.and.pencil.circle.fill" : "square.and.pencil")
                }
                .tag(Tab.log)

            InsightsView()
                .tabItem {
                    Label(Tab.insights.rawValue, systemImage: selectedTab == .insights ? "chart.line.uptrend.xyaxis.circle.fill" : "chart.line.uptrend.xyaxis")
                }
                .tag(Tab.insights)

            ProfileView()
                .tabItem {
                    Label(Tab.profile.rawValue, systemImage: selectedTab == .profile ? "person.fill" : "person")
                }
                .tag(Tab.profile)
        }
        .tint(Color.brandPrimary)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [GlucoseRecord.self, UserSettings.self, MedicationRecord.self], inMemory: true)
        .environment(HealthKitManager())
}
