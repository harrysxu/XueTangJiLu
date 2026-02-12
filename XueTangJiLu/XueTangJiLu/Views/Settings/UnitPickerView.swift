//
//  UnitPickerView.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import SwiftUI
import SwiftData

/// 单位选择页面
struct UnitPickerView: View {
    @Query private var settingsArray: [UserSettings]

    private var settings: UserSettings? {
        settingsArray.first
    }

    var body: some View {
        List {
            ForEach(GlucoseUnit.allCases, id: \.self) { unit in
                Button(action: {
                    HapticManager.selection()
                    settings?.preferredUnit = unit
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(unit.rawValue)
                                .font(.body)
                                .foregroundStyle(.primary)

                            Text(unitDescription(unit))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if settings?.preferredUnit == unit {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.brandPrimary)
                                .fontWeight(.semibold)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("血糖单位")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func unitDescription(_ unit: GlucoseUnit) -> String {
        switch unit {
        case .mmolL: return "中国、欧洲等地区常用"
        case .mgdL:  return "美国、日本等地区常用"
        }
    }
}

#Preview {
    NavigationStack {
        UnitPickerView()
    }
    .modelContainer(for: [UserSettings.self], inMemory: true)
}
