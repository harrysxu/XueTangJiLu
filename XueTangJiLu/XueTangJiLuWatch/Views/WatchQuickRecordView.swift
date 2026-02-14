//
//  WatchQuickRecordView.swift
//  XueTangJiLuWatch
//
//  Created by AI Assistant on 2026/2/14.
//

import SwiftUI
import SwiftData

/// Watch 快速记录页
struct WatchQuickRecordView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var settingsArray: [UserSettings]
    @State private var glucoseValue: Double = 6.0
    @State private var selectedMealContext: MealContext = TagEngine.suggestContext()

    private var settings: UserSettings {
        settingsArray.first ?? UserSettings()
    }

    private var unit: GlucoseUnit {
        settings.preferredUnit
    }

    /// 步进值
    private var step: Double {
        unit == .mmolL ? 0.1 : 1.0
    }

    /// 范围
    private var range: ClosedRange<Double> {
        unit.minValue...unit.maxValue
    }

    /// 显示值
    private var displayValue: String {
        if unit == .mmolL {
            return String(format: "%.1f", glucoseValue)
        }
        return String(format: "%.0f", glucoseValue)
    }

    /// mmol/L 内部值
    private var normalizedValue: Double {
        GlucoseUnitConverter.normalize(value: glucoseValue, preferredUnit: unit)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // 数值显示
                Text(displayValue)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.forGlucoseValue(normalizedValue))

                Text(unit.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                // 数值调节 - 使用 Digital Crown
                Slider(value: $glucoseValue, in: range, step: step)
                    .tint(Color("BrandPrimary"))

                // 餐点选择（简化版，只显示常用的）
                HStack(spacing: 4) {
                    watchMealButton(.beforeBreakfast, icon: "sunrise")
                    watchMealButton(.afterLunch, icon: "sun.max")
                    watchMealButton(.afterDinner, icon: "sunset")
                    watchMealButton(.fasting, icon: "moon.zzz")
                }

                // 保存
                Button(action: saveRecord) {
                    Text("保存")
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("BrandPrimary"))
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle("记录血糖")
    }

    private func watchMealButton(_ context: MealContext, icon: String) -> some View {
        Button(action: {
            selectedMealContext = context
        }) {
            Image(systemName: icon)
                .font(.caption2)
                .frame(width: 28, height: 28)
                .background(
                    selectedMealContext == context
                        ? Color("BrandPrimary")
                        : Color(.darkGray).opacity(0.3)
                )
                .foregroundStyle(selectedMealContext == context ? .white : .secondary)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private func saveRecord() {
        let mmolLValue = normalizedValue
        let record = GlucoseRecord(
            value: mmolLValue,
            timestamp: .now,
            mealContext: selectedMealContext
        )
        modelContext.insert(record)
        dismiss()
    }
}
