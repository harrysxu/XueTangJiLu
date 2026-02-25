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

    enum Tab: String, CaseIterable {
        case dashboard
        case log
        case statistics
        case profile
        
        /// 本地化的标题
        var localizedTitle: String {
            switch self {
            case .dashboard:  return String(localized: "tab.dashboard")
            case .log:        return String(localized: "tab.log")
            case .statistics: return String(localized: "tab.statistics")
            case .profile:    return String(localized: "tab.profile")
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label(Tab.dashboard.localizedTitle, systemImage: selectedTab == .dashboard ? "house.fill" : "house")
                }
                .tag(Tab.dashboard)

            LogView()
                .tabItem {
                    Label(Tab.log.localizedTitle, systemImage: selectedTab == .log ? "square.and.pencil.circle.fill" : "square.and.pencil")
                }
                .tag(Tab.log)

            StatisticsView()
                .tabItem {
                    Label(Tab.statistics.localizedTitle, systemImage: selectedTab == .statistics ? "chart.bar.xaxis.ascending" : "chart.bar.xaxis")
                }
                .tag(Tab.statistics)

            ProfileView()
                .tabItem {
                    Label(Tab.profile.localizedTitle, systemImage: selectedTab == .profile ? "person.fill" : "person")
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
