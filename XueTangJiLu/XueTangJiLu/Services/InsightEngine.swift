//
//  InsightEngine.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/14.
//

import Foundation

/// 血糖模式洞察
struct GlucoseInsight: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let category: InsightCategory

    enum InsightCategory {
        case positive   // 积极
        case warning    // 警告
        case info       // 信息
    }
}

/// 智能洞察引擎 - 分析血糖数据模式并生成个性化建议
struct InsightEngine {

    // MARK: - 主要入口

    /// 根据所有记录生成洞察列表
    static func generateInsights(
        records: [GlucoseRecord],
        targetLow: Double = 3.9,
        targetHigh: Double = 10.0
    ) -> [GlucoseInsight] {
        var insights: [GlucoseInsight] = []

        let weekRecords = records.filter { $0.timestamp >= Date.daysAgo(7) }
        let twoWeekRecords = records.filter { $0.timestamp >= Date.daysAgo(14) }

        // 1. TIR 趋势
        if let tirInsight = analyzeTIRTrend(weekRecords: weekRecords, twoWeekRecords: twoWeekRecords, low: targetLow, high: targetHigh) {
            insights.append(tirInsight)
        }

        // 2. 餐后高血糖模式
        if let mealInsight = analyzeMealPatterns(records: weekRecords) {
            insights.append(mealInsight)
        }

        // 3. 黎明现象检测
        if let dawnInsight = analyzeDawnPhenomenon(records: weekRecords) {
            insights.append(dawnInsight)
        }

        // 4. 波动趋势
        if let cvInsight = analyzeVariability(records: weekRecords) {
            insights.append(cvInsight)
        }

        // 5. 记录频率
        if let freqInsight = analyzeRecordingFrequency(records: weekRecords) {
            insights.append(freqInsight)
        }

        // 6. 低血糖风险
        if let hypoInsight = analyzeHypoglycemiaRisk(records: weekRecords) {
            insights.append(hypoInsight)
        }

        // 7. 时段分析
        if let timeInsight = analyzeTimeOfDayPatterns(records: weekRecords) {
            insights.append(timeInsight)
        }

        return insights
    }

    // MARK: - TIR 趋势分析

    private static func analyzeTIRTrend(
        weekRecords: [GlucoseRecord],
        twoWeekRecords: [GlucoseRecord],
        low: Double,
        high: Double
    ) -> GlucoseInsight? {
        guard !weekRecords.isEmpty else { return nil }

        let currentTIR = GlucoseCalculator.timeInRange(records: weekRecords, low: low, high: high)
        let lastWeek = twoWeekRecords.filter { $0.timestamp < Date.daysAgo(7) }

        if !lastWeek.isEmpty {
            let prevTIR = GlucoseCalculator.timeInRange(records: lastWeek, low: low, high: high)
            let diff = currentTIR - prevTIR

            if diff > 5 {
                return GlucoseInsight(
                    icon: "arrow.up.right.circle.fill",
                    title: "达标率提升",
                    description: "本周 TIR 达到 \(Int(currentTIR))%，较上周提升了 \(Int(diff)) 个百分点，继续保持！",
                    category: .positive
                )
            } else if diff < -5 {
                return GlucoseInsight(
                    icon: "arrow.down.right.circle.fill",
                    title: "达标率下降",
                    description: "本周 TIR 为 \(Int(currentTIR))%，较上周下降了 \(Int(abs(diff))) 个百分点，注意调整",
                    category: .warning
                )
            }
        }

        if currentTIR >= 70 {
            return GlucoseInsight(
                icon: "checkmark.seal.fill",
                title: "血糖控制良好",
                description: "本周达标率 \(Int(currentTIR))%，已达到 70% 的推荐目标",
                category: .positive
            )
        }

        return nil
    }

    // MARK: - 餐后高血糖模式

    private static func analyzeMealPatterns(records: [GlucoseRecord]) -> GlucoseInsight? {
        let afterMealRecords = records.filter {
            [.afterBreakfast, .afterLunch, .afterDinner].contains($0.mealContext)
        }

        guard afterMealRecords.count >= 3 else { return nil }

        let highAfterMeal = afterMealRecords.filter { $0.value >= 10.0 }
        let ratio = Double(highAfterMeal.count) / Double(afterMealRecords.count)

        if ratio >= 0.5 {
            // 分析哪餐最高
            let byMeal = Dictionary(grouping: highAfterMeal) { $0.mealContext }
            let worstMeal = byMeal.max(by: { $0.value.count < $1.value.count })

            let mealName: String
            switch worstMeal?.key {
            case .afterBreakfast: mealName = "早餐后"
            case .afterLunch:     mealName = "午餐后"
            case .afterDinner:    mealName = "晚餐后"
            default:              mealName = "餐后"
            }

            return GlucoseInsight(
                icon: "fork.knife.circle.fill",
                title: "\(mealName)血糖偏高",
                description: "近一周有 \(Int(ratio * 100))% 的餐后血糖超过 10.0 mmol/L，建议关注\(mealName)饮食",
                category: .warning
            )
        }

        return nil
    }

    // MARK: - 黎明现象检测

    private static func analyzeDawnPhenomenon(records: [GlucoseRecord]) -> GlucoseInsight? {
        let fastingRecords = records.filter { $0.mealContext == .fasting || $0.mealContext == .beforeBreakfast }
        guard fastingRecords.count >= 3 else { return nil }

        let highFasting = fastingRecords.filter { $0.value >= 7.0 }
        let ratio = Double(highFasting.count) / Double(fastingRecords.count)

        if ratio >= 0.5 {
            return GlucoseInsight(
                icon: "sunrise.fill",
                title: "空腹血糖偏高",
                description: "近期 \(Int(ratio * 100))% 的空腹血糖偏高，可能存在黎明现象，建议咨询医生",
                category: .warning
            )
        }

        return nil
    }

    // MARK: - 波动分析

    private static func analyzeVariability(records: [GlucoseRecord]) -> GlucoseInsight? {
        guard let cv = GlucoseCalculator.coefficientOfVariation(records: records) else { return nil }

        if cv < 30 {
            return GlucoseInsight(
                icon: "waveform.path.ecg",
                title: "血糖波动平稳",
                description: "本周 CV% 为 \(String(format: "%.1f%%", cv))，血糖非常平稳",
                category: .positive
            )
        } else if cv > 36 {
            return GlucoseInsight(
                icon: "waveform.path.ecg.rectangle.fill",
                title: "血糖波动较大",
                description: "本周 CV% 为 \(String(format: "%.1f%%", cv))，建议关注饮食规律和用药时间",
                category: .warning
            )
        }

        return nil
    }

    // MARK: - 记录频率

    private static func analyzeRecordingFrequency(records: [GlucoseRecord]) -> GlucoseInsight? {
        let avgPerDay = Double(records.count) / 7.0

        if avgPerDay < 2 {
            return GlucoseInsight(
                icon: "clock.badge.exclamationmark.fill",
                title: "记录不够频繁",
                description: "本周平均每天仅记录 \(String(format: "%.1f", avgPerDay)) 次，建议每天至少记录 3-4 次",
                category: .info
            )
        } else if avgPerDay >= 4 {
            return GlucoseInsight(
                icon: "star.circle.fill",
                title: "记录习惯很棒",
                description: "本周平均每天记录 \(String(format: "%.1f", avgPerDay)) 次，保持这个好习惯！",
                category: .positive
            )
        }

        return nil
    }

    // MARK: - 低血糖风险

    private static func analyzeHypoglycemiaRisk(records: [GlucoseRecord]) -> GlucoseInsight? {
        let hypoRecords = records.filter { $0.value < 3.9 }
        guard !hypoRecords.isEmpty else { return nil }

        return GlucoseInsight(
            icon: "exclamationmark.triangle.fill",
            title: "注意低血糖",
            description: "本周出现 \(hypoRecords.count) 次低血糖（< 3.9 mmol/L），请及时补充能量并咨询医生",
            category: .warning
        )
    }

    // MARK: - 时段分析

    private static func analyzeTimeOfDayPatterns(records: [GlucoseRecord]) -> GlucoseInsight? {
        guard records.count >= 7 else { return nil }

        let calendar = Calendar.current

        // 按时段分组
        let morningRecords = records.filter {
            let hour = calendar.component(.hour, from: $0.timestamp)
            return hour >= 6 && hour < 12
        }
        let afternoonRecords = records.filter {
            let hour = calendar.component(.hour, from: $0.timestamp)
            return hour >= 12 && hour < 18
        }
        let eveningRecords = records.filter {
            let hour = calendar.component(.hour, from: $0.timestamp)
            return hour >= 18 || hour < 6
        }

        let periods: [(String, [GlucoseRecord])] = [
            ("上午", morningRecords),
            ("下午", afternoonRecords),
            ("晚间", eveningRecords)
        ]

        // 找平均最高的时段
        var highest: (String, Double) = ("", 0)
        for (name, recs) in periods {
            guard !recs.isEmpty else { continue }
            let avg = recs.reduce(0.0) { $0 + $1.value } / Double(recs.count)
            if avg > highest.1 {
                highest = (name, avg)
            }
        }

        if highest.1 >= 8.0 {
            return GlucoseInsight(
                icon: "chart.bar.fill",
                title: "\(highest.0)血糖偏高",
                description: "\(highest.0)时段的平均血糖为 \(String(format: "%.1f", highest.1)) mmol/L，可以关注该时段的饮食和活动",
                category: .info
            )
        }

        return nil
    }
}
