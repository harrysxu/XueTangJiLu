//
//  AboutView.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import SwiftUI

/// 关于页面类型
enum AboutType {
    case privacy
    case disclaimer

    var title: String {
        switch self {
        case .privacy:    return String(localized: "about.privacy.title")
        case .disclaimer: return String(localized: "about.disclaimer.title")
        }
    }

    var content: String {
        switch self {
        case .privacy:
            return String(localized: "about.privacy.content")

        case .disclaimer:
            return String(localized: "about.disclaimer.content")
        }
    }
}

/// 关于/隐私政策/免责声明页面
struct AboutView: View {
    let type: AboutType

    var body: some View {
        ScrollView {
            Text(type.content)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(AppConstants.Spacing.xl)
        }
        .navigationTitle(type.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AboutView(type: .disclaimer)
    }
}
