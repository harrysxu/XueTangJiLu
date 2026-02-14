//
//  MinimalKeypadView.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import SwiftUI

/// 自定义数字键盘
struct MinimalKeypadView: View {
    let onKeyPress: (KeypadKey) -> Void

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            // Row 1: 1, 2, 3
            ForEach(1...3, id: \.self) { num in
                KeypadButton(label: "\(num)") {
                    onKeyPress(.digit(num))
                }
            }
            // Row 2: 4, 5, 6
            ForEach(4...6, id: \.self) { num in
                KeypadButton(label: "\(num)") {
                    onKeyPress(.digit(num))
                }
            }
            // Row 3: 7, 8, 9
            ForEach(7...9, id: \.self) { num in
                KeypadButton(label: "\(num)") {
                    onKeyPress(.digit(num))
                }
            }
            // Row 4: ., 0, ⌫
            KeypadButton(label: ".") {
                onKeyPress(.decimal)
            }
            KeypadButton(label: "0") {
                onKeyPress(.digit(0))
            }
            KeypadButton(icon: "delete.left") {
                onKeyPress(.delete)
            }
        }
        .padding(.horizontal, AppConstants.Spacing.lg)
    }
}

/// 单个键盘按键
struct KeypadButton: View {
    let label: String?
    let icon: String?
    let identifier: String
    let action: () -> Void

    init(label: String, action: @escaping () -> Void) {
        self.label = label
        self.icon = nil
        self.identifier = "keypad_\(label == "." ? "dot" : label)"
        self.action = action
    }

    init(icon: String, action: @escaping () -> Void) {
        self.label = nil
        self.icon = icon
        self.identifier = "keypad_delete"
        self.action = action
    }

    var body: some View {
        Button(action: {
            HapticManager.light()
            action()
        }) {
            Group {
                if let label {
                    Text(label)
                        .font(.keypadButton)
                } else if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                }
            }
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
            .frame(height: AppConstants.Size.keypadButtonHeight)
            .background(Color(.tertiarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.buttonMedium))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
        .accessibilityLabel(accessLabel)
    }

    private var accessLabel: String {
        if let label {
            switch label {
            case ".": return "小数点"
            case "0": return "零"
            default: return label
            }
        }
        if icon == "delete.left" {
            return "删除"
        }
        return ""
    }
}

#Preview {
    MinimalKeypadView { key in
        print("Key pressed: \(key)")
    }
    .padding()
}
