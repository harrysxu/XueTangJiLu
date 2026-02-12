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
        case .privacy:    return "隐私政策"
        case .disclaimer: return "免责声明"
        }
    }

    var content: String {
        switch self {
        case .privacy:
            return """
            学糖记录 隐私政策

            最后更新：2026年2月12日

            1. 数据收集
            本应用不收集任何个人信息到开发者服务器。所有血糖记录数据仅存储在您的设备本地和您的私人 iCloud 账户中。

            2. 数据存储
            • 本地存储：血糖记录保存在您设备的本地数据库中
            • iCloud 同步：如果您启用了 iCloud，数据将通过您的私人 iCloud 账户在您的设备之间同步
            • Apple Health：如果您授权，血糖数据将同步到 Apple Health 应用

            3. 数据安全
            • 所有本地数据受 iOS 系统级加密保护
            • iCloud 传输使用 TLS 加密
            • 开发者无法访问您的任何数据

            4. 第三方服务
            本应用不集成任何第三方分析、广告或追踪 SDK。

            5. 数据导出与删除
            • 您可以随时通过设置页面导出所有数据（PDF 或 CSV 格式）
            • 您可以随时删除任何记录
            • 删除应用将移除所有本地数据（iCloud 和 Health 中的数据需单独管理）

            6. 联系我们
            如有隐私相关问题，请通过 App Store 页面联系我们。
            """

        case .disclaimer:
            return """
            免责声明

            重要提示：请在使用本应用前仔细阅读以下内容。

            1. 非医疗设备
            学糖记录（XueTangJiLu）是一款个人健康数据记录工具，不是医疗器械，不具备医疗诊断功能。

            2. 不提供医疗建议
            本应用不提供任何形式的医疗诊断、治疗建议或用药指导。应用中显示的统计数据（如预估 A1C、达标率等）仅供参考，不应作为医疗决策的依据。

            3. 咨询医生
            在做出任何医疗相关决定之前，请务必咨询您的医生或专业医疗人员。不要根据本应用中的数据自行调整药物剂量或治疗方案。

            4. 数据准确性
            本应用记录的数据基于用户手动输入，数据的准确性由用户自行负责。请确保您输入的血糖数值与血糖仪显示一致。

            5. 紧急情况
            如果您出现严重低血糖、高血糖或其他紧急医疗状况，请立即拨打急救电话或前往最近的医疗机构。

            6. 责任限制
            在法律允许的最大范围内，开发者不对因使用本应用而产生的任何直接或间接损失承担责任。
            """
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
