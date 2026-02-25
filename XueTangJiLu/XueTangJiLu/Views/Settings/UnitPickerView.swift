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
        .navigationTitle(String(localized: "unit.title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func unitDescription(_ unit: GlucoseUnit) -> String {
        switch unit {
        case .mmolL: return String(localized: "unit.mmol_region")
        case .mgdL:  return String(localized: "unit.mgdl_region")
        }
    }
}

#Preview {
    NavigationStack {
        UnitPickerView()
    }
    .modelContainer(for: [UserSettings.self], inMemory: true)
}
