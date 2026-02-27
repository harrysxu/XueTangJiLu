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
                        String(localized: "date_range.start_date"),
                        selection: $tempStartDate,
                        in: ...tempEndDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.compact)
                    
                    DatePicker(
                        String(localized: "date_range.end_date"),
                        selection: $tempEndDate,
                        in: tempStartDate...Date.now,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.compact)
                } header: {
                    Text("date_range.select_range")
                } footer: {
                    Text("date_range.select_range_footer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("date_range.custom")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("date_range.confirm") {
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
