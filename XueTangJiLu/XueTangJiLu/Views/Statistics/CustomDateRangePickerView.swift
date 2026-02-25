//
//  CustomDateRangePickerView.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/20.
//

import SwiftUI

/// 自定义日期范围选择器
struct CustomDateRangePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var startDate: Date
    @Binding var endDate: Date
    
    @State private var tempStartDate: Date
    @State private var tempEndDate: Date
    
    init(startDate: Binding<Date>, endDate: Binding<Date>) {
        self._startDate = startDate
        self._endDate = endDate
        self._tempStartDate = State(initialValue: startDate.wrappedValue)
        self._tempEndDate = State(initialValue: endDate.wrappedValue)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        "开始日期",
                        selection: $tempStartDate,
                        in: ...tempEndDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.compact)
                    
                    DatePicker(
                        "结束日期",
                        selection: $tempEndDate,
                        in: tempStartDate...Date.now,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.compact)
                } header: {
                    Text("选择日期范围")
                } footer: {
                    Text("选择要查看的起止日期")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("自定义时间范围")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("确定") {
                        startDate = tempStartDate
                        endDate = tempEndDate
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValidRange)
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private var isValidRange: Bool {
        tempStartDate <= tempEndDate
    }
}

#Preview {
    CustomDateRangePickerView(
        startDate: .constant(Date.daysAgo(7)),
        endDate: .constant(Date.now)
    )
}
