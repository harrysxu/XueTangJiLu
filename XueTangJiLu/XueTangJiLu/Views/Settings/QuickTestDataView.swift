//
//  QuickTestDataView.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/20.
//

import SwiftUI
import SwiftData

/// 快速测试数据生成视图 - 用于验证首页时间轴功能
struct QuickTestDataView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var isGenerating = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button("生成一条血糖记录") {
                        generateGlucoseRecord()
                    }
                    
                    Button("生成一条用药记录") {
                        generateMedicationRecord()
                    }
                    
                    Button("生成一条饮食记录（无照片）") {
                        generateMealRecord()
                    }
                } header: {
                    Text("单条记录")
                }
                
                Section {
                    Button("生成完整测试数据集") {
                        generateFullTestData()
                    }
                    .disabled(isGenerating)
                } header: {
                    Text("批量生成")
                } footer: {
                    Text("将生成今天的血糖、用药、饮食记录各3条，用于测试首页时间轴展示")
                }
            }
            .navigationTitle("测试数据生成器")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - 生成方法
    
    private func generateGlucoseRecord() {
        let record = GlucoseRecord(
            value: Double.random(in: 4.0...8.0),
            timestamp: Date.now.addingTimeInterval(-Double.random(in: 0...3600)),
            sceneTagId: MealContext.allCases.randomElement()?.rawValue ?? MealContext.other.rawValue,
            note: ["早餐后", "运动后", "睡前"].randomElement()
        )
        modelContext.insert(record)
        HapticManager.success()
    }
    
    private func generateMedicationRecord() {
        let types: [MedicationType] = [.rapidInsulin, .longInsulin, .oralMedicine]
        let type = types.randomElement() ?? .rapidInsulin
        
        let record = MedicationRecord(
            medicationType: type,
            name: ["诺和锐", "优泌乐", "二甲双胍"].randomElement() ?? "",
            dosage: Double.random(in: 4...12),
            timestamp: Date.now.addingTimeInterval(-Double.random(in: 0...3600)),
            note: nil
        )
        modelContext.insert(record)
        HapticManager.success()
    }
    
    private func generateMealRecord() {
        let levels: [CarbLevel] = [.low, .medium, .high]
        let descriptions = [
            "鸡胸肉沙拉",
            "米饭 + 青菜 + 鸡蛋",
            "红烧肉 + 米饭",
            "全麦面包 + 牛奶",
            "水果拼盘"
        ]
        
        let record = MealRecord(
            carbLevel: levels.randomElement() ?? .medium,
            mealDescription: descriptions.randomElement() ?? "饮食",
            photoData: nil,
            timestamp: Date.now.addingTimeInterval(-Double.random(in: 0...3600)),
            note: nil
        )
        modelContext.insert(record)
        HapticManager.success()
    }
    
    private func generateFullTestData() {
        isGenerating = true
        
        // 生成3条血糖记录
        for i in 0..<3 {
            let record = GlucoseRecord(
                value: [5.5, 6.8, 7.2][i],
                timestamp: Date.now.addingTimeInterval(-Double(i * 3600)),
                sceneTagId: [MealContext.beforeBreakfast, MealContext.afterLunch, MealContext.beforeDinner][i].rawValue,
                note: nil
            )
            modelContext.insert(record)
        }
        
        // 生成3条用药记录
        for i in 0..<3 {
            let record = MedicationRecord(
                medicationType: [.rapidInsulin, .rapidInsulin, .longInsulin][i],
                name: ["诺和锐", "诺和锐", "来得时"][i],
                dosage: [8.0, 6.0, 12.0][i],
                timestamp: Date.now.addingTimeInterval(-Double(i * 3600 + 1800)),
                note: nil
            )
            modelContext.insert(record)
        }
        
        // 生成3条饮食记录
        for i in 0..<3 {
            let record = MealRecord(
                carbLevel: [.medium, .high, .low][i],
                mealDescription: ["全麦面包 + 鸡蛋", "米饭 + 红烧肉", "鸡胸肉沙拉"][i],
                photoData: nil,
                timestamp: Date.now.addingTimeInterval(-Double(i * 3600 + 900)),
                note: nil
            )
            modelContext.insert(record)
        }
        
        HapticManager.success()
        isGenerating = false
        
        // 自动关闭
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
    }
}

#Preview {
    QuickTestDataView()
        .modelContainer(for: [GlucoseRecord.self, MedicationRecord.self, MealRecord.self], inMemory: true)
}
