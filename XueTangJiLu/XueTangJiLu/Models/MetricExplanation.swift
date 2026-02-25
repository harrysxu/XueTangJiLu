//
//  MetricExplanation.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/19.
//

import Foundation

/// 指标类型枚举
enum MetricType: String, CaseIterable {
    case averageGlucose = "average_glucose"
    case estimatedA1C = "estimated_a1c"
    case timeInRange = "time_in_range"
    case coefficientOfVariation = "coefficient_of_variation"
    case timeAboveRange = "time_above_range"
    case timeBelowRange = "time_below_range"
    case glucoseDistribution = "glucose_distribution"
    case perTagTIR = "per_tag_tir"
    case mealPair = "meal_pair"
    case tagDistribution = "tag_distribution"
    case weeklyComparison = "weekly_comparison"
    case hourlyDistribution = "hourly_distribution"
    case dailyTrend = "daily_trend"
}

/// 指标解释内容结构
struct MetricExplanation {
    let type: MetricType
    let title: String
    let briefDescription: String
    let formula: String?
    let referenceStandard: String?
    let clinicalSignificance: String
    let practicalUse: String
    
    init(
        type: MetricType,
        title: String,
        briefDescription: String,
        formula: String? = nil,
        referenceStandard: String? = nil,
        clinicalSignificance: String,
        practicalUse: String
    ) {
        self.type = type
        self.title = title
        self.briefDescription = briefDescription
        self.formula = formula
        self.referenceStandard = referenceStandard
        self.clinicalSignificance = clinicalSignificance
        self.practicalUse = practicalUse
    }
}

/// 指标解释内容库
struct MetricExplanationLibrary {
    
    static let explanations: [MetricType: MetricExplanation] = [
        .averageGlucose: MetricExplanation(
            type: .averageGlucose,
            title: "平均血糖",
            briefDescription: "所有记录的算术平均值",
            formula: "平均血糖 = 所有血糖记录之和 ÷ 记录总数",
            referenceStandard: "餐前 4.4-7.0 mmol/L，餐后 < 10.0 mmol/L",
            clinicalSignificance: "反映选定时间段内的整体血糖控制水平，是计算估算糖化的基础指标。",
            practicalUse: "帮助了解血糖总体趋势，配合达标率和波动系数可全面评估血糖管理效果。"
        ),
        
        .estimatedA1C: MetricExplanation(
            type: .estimatedA1C,
            title: "估算糖化 (eA1C)",
            briefDescription: "根据平均血糖估算的糖化血红蛋白值，仅供参考",
            formula: "eA1C (%) = (平均血糖 × 18.0182 + 46.7) ÷ 28.7",
            referenceStandard: "< 7.0% 良好，7.0-8.0% 尚可，> 8.0% 需改善",
            clinicalSignificance: "糖化血红蛋白反映近2-3个月的血糖控制情况，是糖尿病管理的金标准。估算值可作为日常参考，但不能替代医院检测。",
            practicalUse: "帮助日常监测血糖控制趋势，及时调整饮食和用药方案。每次就医前可参考估算值与医生沟通。"
        ),
        
        .timeInRange: MetricExplanation(
            type: .timeInRange,
            title: "达标率 (TIR)",
            briefDescription: "血糖值落在目标范围内的记录占比",
            formula: "达标率 (%) = (达标记录数 ÷ 总记录数) × 100%",
            referenceStandard: "> 70% 良好，50-70% 尚可，< 50% 需改善",
            clinicalSignificance: "Time in Range (TIR) 是国际推荐的核心血糖控制指标，比糖化血红蛋白更能反映血糖波动情况。",
            practicalUse: "综合评估血糖管理效果，比单纯看平均值更全面。可以发现血糖是否经常超出目标范围，指导调整治疗方案。"
        ),
        
        .coefficientOfVariation: MetricExplanation(
            type: .coefficientOfVariation,
            title: "波动系数 (CV%)",
            briefDescription: "数值越小，血糖越稳定",
            formula: "CV% = (标准差 ÷ 平均值) × 100%",
            referenceStandard: "< 36% 稳定，≥ 36% 波动较大",
            clinicalSignificance: "评估血糖稳定性的关键指标。血糖波动过大可能增加低血糖风险和并发症发生率，即使平均值正常也需要关注。",
            practicalUse: "指导饮食规律性和用药时机。波动大提示需要调整饮食结构、规律进餐时间，或与医生讨论用药方案。"
        ),
        
        .timeAboveRange: MetricExplanation(
            type: .timeAboveRange,
            title: "高于范围 (TAR)",
            briefDescription: "血糖值高于目标范围的记录占比",
            formula: "TAR (%) = (高血糖记录数 ÷ 总记录数) × 100%",
            referenceStandard: "< 25% 为目标，越低越好",
            clinicalSignificance: "反映高血糖发生频率。长期高血糖会增加糖尿病并发症风险，需要及时控制。",
            practicalUse: "帮助识别高血糖发生的时段和场景，针对性调整饮食或用药。"
        ),
        
        .timeBelowRange: MetricExplanation(
            type: .timeBelowRange,
            title: "低于范围 (TBR)",
            briefDescription: "血糖值低于目标范围的记录占比",
            formula: "TBR (%) = (低血糖记录数 ÷ 总记录数) × 100%",
            referenceStandard: "< 4% 为目标，越低越好",
            clinicalSignificance: "反映低血糖发生频率。低血糖有急性危险，需要特别重视和预防。",
            practicalUse: "帮助识别低血糖风险时段，调整用药剂量或进餐时间，避免危险。"
        ),
        
        .glucoseDistribution: MetricExplanation(
            type: .glucoseDistribution,
            title: "血糖分布",
            briefDescription: "直观展示血糖在不同范围的分布情况",
            formula: nil,
            referenceStandard: "低于范围 < 4%，达标范围 > 70%，高于范围 < 25%",
            clinicalSignificance: "三段式血糖分布图可以快速识别血糖管理的主要问题：是高血糖多还是低血糖多。",
            practicalUse: "帮助制定个性化的血糖管理策略。如果高血糖占比大，需要控制饮食或调整用药；如果低血糖多，需要减少用药或增加进食。"
        ),
        
        .perTagTIR: MetricExplanation(
            type: .perTagTIR,
            title: "各场景达标率",
            briefDescription: "每个场景按其独立阈值计算达标率",
            formula: "各场景独立计算：(该场景达标记录数 ÷ 该场景总记录数) × 100%",
            referenceStandard: "各场景目标 > 70%",
            clinicalSignificance: "不同场景（餐前、餐后等）有不同的血糖目标范围。分场景评估可以发现特定时段的管理问题。",
            practicalUse: "帮助识别哪个场景的血糖控制较差，针对性调整该时段的饮食或用药。例如餐后达标率低，可能需要控制碳水化合物摄入。"
        ),
        
        .mealPair: MetricExplanation(
            type: .mealPair,
            title: "餐前餐后配对",
            briefDescription: "基于时间自动配对的血糖升幅分析",
            formula: "升幅 = 餐后血糖 - 餐前血糖\n\n配对规则（完全基于时间）：\n• 同一天内\n• 餐后时间晚于餐前\n• 时间间隔 ≤ 4小时\n• 选择时间最接近的餐前记录\n\n注意：配对不考虑标签名称语义，仅依据阈值分组（餐前/餐后）和时间关系。例如「下午吃饭前」和「下午喝茶后」若符合上述规则也会配对。",
            referenceStandard: "升幅 < 3.0 mmol/L 为理想",
            clinicalSignificance: "餐后血糖升幅反映饮食对血糖的影响。升幅过大说明进餐后血糖波动大，可能增加并发症风险。",
            practicalUse: "帮助评估具体某餐的血糖影响，指导调整食物种类和分量。升幅大的餐次可以考虑减少碳水化合物或增加餐前用药。建议每餐的餐前餐后记录保持规律，以确保配对的准确性。"
        ),
        
        .tagDistribution: MetricExplanation(
            type: .tagDistribution,
            title: "各场景血糖分布",
            briefDescription: "箱线图直观展示各场景的血糖分布特征",
            formula: "• 粗线：典型值（中位数，50%分位）\n• 盒子：日常范围（四分位距，包含中间50%的数据）\n• 细线：极值（最高和最低记录）\n• 浅绿区域：该场景的目标范围",
            referenceStandard: "典型值应在目标范围内，日常范围越窄表示血糖越稳定",
            clinicalSignificance: "箱线图可同时展示血糖的集中趋势、离散程度和极值。粗线位置反映典型水平，盒子宽度反映稳定性，细线显示波动幅度。",
            practicalUse: "快速识别需要重点关注的场景：典型值偏离目标说明该场景控制不佳；盒子较宽说明血糖不稳定；极值偏离严重提示有异常波动。"
        ),
        
        .weeklyComparison: MetricExplanation(
            type: .weeklyComparison,
            title: "周对比",
            briefDescription: "对比本周与上周的血糖变化趋势",
            formula: "分别计算本周和上周的平均血糖、达标率",
            referenceStandard: "趋势向好：均值下降且达标率上升",
            clinicalSignificance: "周对周比较可以及时发现血糖管理的改善或恶化，比月度或季度评估更敏感。",
            practicalUse: "帮助评估近期饮食、运动、用药调整的效果。如果本周数据变好，说明调整有效；如果变差，需要找出原因并改进。"
        ),
        
        .hourlyDistribution: MetricExplanation(
            type: .hourlyDistribution,
            title: "时段分布",
            briefDescription: "24小时热力图展示该场景在不同时段的血糖表现",
            formula: "按小时统计：每小时的平均血糖和记录次数",
            referenceStandard: "根据场景目标范围评估",
            clinicalSignificance: "发现一天中不同时段的血糖规律，识别高风险时段。",
            practicalUse: "帮助找出容易出现高血糖或低血糖的具体时间段，针对性调整作息、饮食或用药时间。"
        ),
        
        .dailyTrend: MetricExplanation(
            type: .dailyTrend,
            title: "日期趋势",
            briefDescription: "逐日统计该场景的血糖变化",
            formula: "每日统计：平均值、最高最低值、记录次数、达标率",
            referenceStandard: "根据场景目标范围评估",
            clinicalSignificance: "追踪该场景血糖的日间变化趋势，识别管理改善或恶化。",
            practicalUse: "帮助回顾每天的血糖表现，结合饮食日记找出影响因素，持续优化管理策略。"
        )
    ]
    
    /// 获取指定指标的解释
    static func explanation(for type: MetricType) -> MetricExplanation? {
        return explanations[type]
    }
    
    /// 获取指定指标的简短说明
    static func briefDescription(for type: MetricType) -> String {
        return explanations[type]?.briefDescription ?? ""
    }
}
