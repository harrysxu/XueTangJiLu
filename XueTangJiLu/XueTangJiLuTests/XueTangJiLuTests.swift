//
//  XueTangJiLuTests.swift
//  XueTangJiLuTests
//
//  Created by 徐晓龙 on 2026/2/12.
//

import Testing
@testable import XueTangJiLu

// MARK: - TagEngine 测试

struct TagEngineTests {

    @Test("早晨 7 点应推荐早餐前标签")
    func morningTag() {
        let date = createDate(hour: 7, minute: 30)
        let context = TagEngine.suggestContext(for: date)
        #expect(context == .beforeBreakfast)
    }

    @Test("上午 8:30 应推荐早餐后标签")
    func afterBreakfastTag() {
        let date = createDate(hour: 8, minute: 30)
        let context = TagEngine.suggestContext(for: date)
        #expect(context == .afterBreakfast)
    }

    @Test("上午 11 点应推荐午餐前标签")
    func beforeLunchTag() {
        let date = createDate(hour: 11, minute: 0)
        let context = TagEngine.suggestContext(for: date)
        #expect(context == .beforeLunch)
    }

    @Test("中午 12:30 应推荐午餐后标签")
    func afterLunchTag() {
        let date = createDate(hour: 12, minute: 30)
        let context = TagEngine.suggestContext(for: date)
        #expect(context == .afterLunch)
    }

    @Test("下午 15 点应推荐晚餐前标签")
    func beforeDinnerTag() {
        let date = createDate(hour: 15, minute: 0)
        let context = TagEngine.suggestContext(for: date)
        #expect(context == .beforeDinner)
    }

    @Test("下午 18 点应推荐晚餐后标签")
    func afterDinnerTag() {
        let date = createDate(hour: 18, minute: 0)
        let context = TagEngine.suggestContext(for: date)
        #expect(context == .afterDinner)
    }

    @Test("晚上 21 点应推荐睡前标签")
    func bedtimeTag() {
        let date = createDate(hour: 21, minute: 0)
        let context = TagEngine.suggestContext(for: date)
        #expect(context == .bedtime)
    }

    @Test("午夜应推荐空腹标签")
    func midnightTag() {
        let date = createDate(hour: 0, minute: 0)
        let context = TagEngine.suggestContext(for: date)
        #expect(context == .fasting)
    }

    @Test("凌晨 3 点应推荐空腹标签")
    func earlyMorningTag() {
        let date = createDate(hour: 3, minute: 0)
        let context = TagEngine.suggestContext(for: date)
        #expect(context == .fasting)
    }

    @Test("晚上 23 点应推荐空腹标签（跨午夜）")
    func lateNightTag() {
        let date = createDate(hour: 23, minute: 0)
        let context = TagEngine.suggestContext(for: date)
        #expect(context == .fasting)
    }

    private func createDate(hour: Int, minute: Int) -> Date {
        var components = Calendar.current.dateComponents(
            [.year, .month, .day], from: .now
        )
        components.hour = hour
        components.minute = minute
        components.second = 0
        return Calendar.current.date(from: components)!
    }
}

// MARK: - GlucoseCalculator 测试

struct GlucoseCalculatorTests {

    @Test("eAG 计算 - 正常数据")
    func estimatedAverageGlucose() {
        let records = [5.0, 6.0, 7.0].map {
            GlucoseRecord(value: $0)
        }
        let avg = GlucoseCalculator.estimatedAverageGlucose(records: records)
        #expect(avg == 6.0)
    }

    @Test("eAG 计算 - 空数组应返回 nil")
    func emptyRecordsAverage() {
        let avg = GlucoseCalculator.estimatedAverageGlucose(records: [])
        #expect(avg == nil)
    }

    @Test("TIR 计算 - 全部达标")
    func tirAllInRange() {
        let records = [5.0, 6.0, 7.0, 8.0, 9.0].map {
            GlucoseRecord(value: $0)
        }
        let tir = GlucoseCalculator.timeInRange(records: records)
        #expect(tir == 100.0)
    }

    @Test("TIR 计算 - 部分达标")
    func tirPartialInRange() {
        let records = [3.0, 5.0, 12.0, 6.5].map {
            GlucoseRecord(value: $0)
        }
        let tir = GlucoseCalculator.timeInRange(records: records)
        #expect(tir == 50.0)
    }

    @Test("TIR 计算 - 空数组应返回 0")
    func tirEmptyRecords() {
        let tir = GlucoseCalculator.timeInRange(records: [])
        #expect(tir == 0.0)
    }

    @Test("eA1C 计算精度")
    func estimatedA1C() {
        // 平均血糖 7.0 mmol/L ≈ 126.1 mg/dL → eA1C ≈ 6.0%
        let a1c = GlucoseCalculator.estimatedA1C(averageGlucoseMmolL: 7.0)
        #expect(a1c > 5.9 && a1c < 6.1)
    }

    @Test("标准差计算")
    func standardDeviation() {
        let records = [4.0, 6.0, 8.0].map {
            GlucoseRecord(value: $0)
        }
        let sd = GlucoseCalculator.standardDeviation(records: records)
        #expect(sd != nil)
        #expect(sd! > 1.9 && sd! < 2.1)
    }

    @Test("CV% 计算")
    func coefficientOfVariation() {
        let records = [5.0, 5.0, 5.0].map {
            GlucoseRecord(value: $0)
        }
        let cv = GlucoseCalculator.coefficientOfVariation(records: records)
        #expect(cv == 0.0)
    }
}

// MARK: - GlucoseUnitConverter 测试

struct UnitConverterTests {

    @Test("mmol/L 转 mg/dL")
    func mmolToMgdl() {
        let result = GlucoseUnitConverter.toMgDL(5.5)
        #expect(abs(result - 99.1) < 0.1)
    }

    @Test("mg/dL 转 mmol/L")
    func mgdlToMmol() {
        let result = GlucoseUnitConverter.toMmolL(100.0)
        #expect(abs(result - 5.55) < 0.05)
    }

    @Test("双向转换一致性")
    func roundTrip() {
        let original = 6.5
        let mgdl = GlucoseUnitConverter.toMgDL(original)
        let backToMmol = GlucoseUnitConverter.toMmolL(mgdl)
        #expect(abs(backToMmol - original) < 0.001)
    }

    @Test("智能单位检测 - 小数值识别为 mmol/L")
    func detectMmolL() {
        let unit = GlucoseUnitConverter.detectUnit(for: 5.5)
        #expect(unit == .mmolL)
    }

    @Test("智能单位检测 - 大数值识别为 mg/dL")
    func detectMgdL() {
        let unit = GlucoseUnitConverter.detectUnit(for: 120)
        #expect(unit == .mgdL)
    }

    @Test("智能单位检测 - 边界值 35 识别为 mmol/L")
    func detectBoundary() {
        let unit = GlucoseUnitConverter.detectUnit(for: 35.0)
        #expect(unit == .mmolL)
    }

    @Test("格式化显示 - mmol/L 保留一位小数")
    func displayMmol() {
        let result = GlucoseUnitConverter.displayString(mmolLValue: 5.55, in: .mmolL)
        #expect(result == "5.6")  // 四舍五入
    }

    @Test("格式化显示 - mg/dL 不含小数")
    func displayMgdl() {
        let result = GlucoseUnitConverter.displayString(mmolLValue: 5.5, in: .mgdL)
        #expect(result == "99")  // 5.5 * 18.0182 ≈ 99.1
    }

    @Test("标准化 - mmol/L 不变")
    func normalizeMmol() {
        let result = GlucoseUnitConverter.normalize(value: 5.5, preferredUnit: .mmolL)
        #expect(result == 5.5)
    }

    @Test("标准化 - mg/dL 转为 mmol/L")
    func normalizeMgdl() {
        let result = GlucoseUnitConverter.normalize(value: 100.0, preferredUnit: .mgdL)
        #expect(abs(result - 5.55) < 0.05)
    }
}

// MARK: - GlucoseLevel 测试

struct GlucoseLevelTests {

    @Test("低血糖判定 (< 3.9)")
    func lowLevel() {
        #expect(GlucoseLevel.from(value: 3.0) == .low)
        #expect(GlucoseLevel.from(value: 3.8) == .low)
    }

    @Test("正常范围判定 (3.9 - 6.9)")
    func normalLevel() {
        #expect(GlucoseLevel.from(value: 3.9) == .normal)
        #expect(GlucoseLevel.from(value: 5.5) == .normal)
        #expect(GlucoseLevel.from(value: 6.9) == .normal)
    }

    @Test("偏高判定 (7.0 - 9.9)")
    func highLevel() {
        #expect(GlucoseLevel.from(value: 7.0) == .high)
        #expect(GlucoseLevel.from(value: 8.5) == .high)
        #expect(GlucoseLevel.from(value: 9.9) == .high)
    }

    @Test("严重偏高判定 (>= 10.0)")
    func veryHighLevel() {
        #expect(GlucoseLevel.from(value: 10.0) == .veryHigh)
        #expect(GlucoseLevel.from(value: 15.0) == .veryHigh)
    }
}

// MARK: - GlucoseUnit 测试

struct GlucoseUnitTests {

    @Test("mmol/L 小数位限制为 1")
    func mmolDecimalPlaces() {
        #expect(GlucoseUnit.mmolL.maxDecimalPlaces == 1)
    }

    @Test("mg/dL 小数位限制为 0")
    func mgdlDecimalPlaces() {
        #expect(GlucoseUnit.mgdL.maxDecimalPlaces == 0)
    }

    @Test("mmol/L 有效范围")
    func mmolRange() {
        #expect(GlucoseUnit.mmolL.minValue == 1.0)
        #expect(GlucoseUnit.mmolL.maxValue == 33.3)
    }

    @Test("mg/dL 有效范围")
    func mgdlRange() {
        #expect(GlucoseUnit.mgdL.minValue == 18.0)
        #expect(GlucoseUnit.mgdL.maxValue == 600.0)
    }
}
