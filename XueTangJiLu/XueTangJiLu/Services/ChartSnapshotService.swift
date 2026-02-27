//
//  ChartSnapshotService.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/21.
//

import SwiftUI
import UIKit

/// 图表快照服务 - 将 SwiftUI 视图渲染为 UIImage
@MainActor
struct ChartSnapshotService {
    
    /// 将 SwiftUI 视图渲染为图片
    /// - Parameters:
    ///   - content: SwiftUI 视图内容
    ///   - size: 图片尺寸
    /// - Returns: 渲染后的 UIImage，失败返回 nil
    static func snapshot<Content: View>(
        @ViewBuilder content: () -> Content,
        size: CGSize
    ) -> UIImage? {
        let renderer = ImageRenderer(content: content())
        renderer.scale = UIScreen.main.scale
        
        // 设置渲染尺寸
        renderer.proposedSize = ProposedViewSize(size)
        
        return renderer.uiImage
    }
    
    /// 渲染趋势折线图
    /// - Parameters:
    ///   - dataPoints: 图表数据点
    ///   - targetLow: 目标范围下限
    ///   - targetHigh: 目标范围上限
    ///   - unit: 单位
    ///   - size: 图片尺寸
    /// - Returns: 趋势图图片
    static func renderTrendChart(
        dataPoints: [ChartDataPoint],
        targetLow: Double,
        targetHigh: Double,
        unit: GlucoseUnit,
        size: CGSize = CGSize(width: 515, height: 200)
    ) -> UIImage? {
        @State var selectedPoint: ChartDataPoint? = nil
        
        return snapshot(content: {
            TrendLineChart(
                dataPoints: dataPoints,
                targetLow: targetLow,
                targetHigh: targetHigh,
                unit: unit,
                selectedPoint: $selectedPoint
            )
            .frame(width: size.width, height: size.height)
            .background(Color.white)
        }, size: size)
    }
    
    /// 渲染各场景 TIR 条形图
    /// - Parameters:
    ///   - records: 血糖记录
    ///   - settings: 用户设置
    ///   - size: 图片尺寸
    /// - Returns: TIR 条形图图片
    static func renderPerTagTIRChart(
        records: [GlucoseRecord],
        settings: UserSettings,
        size: CGSize = CGSize(width: 515, height: 260)
    ) -> UIImage? {
        let byTag = Dictionary(grouping: records) { $0.sceneTagId }
        let sortedTags = byTag.sorted { $0.value.count > $1.value.count }
        
        struct TagTIRData: Identifiable {
            let id = UUID()
            let tagName: String
            let tir: Double
            let count: Int
        }
        
        var data: [TagTIRData] = []
        for (tagId, tagRecords) in sortedTags.prefix(8) {
            let tagName = settings.displayName(for: tagId)
            let range = settings.thresholdRange(for: tagId)
            let inRange = tagRecords.filter { $0.value >= range.low && $0.value <= range.high }
            let tir = Double(inRange.count) / Double(tagRecords.count) * 100.0
            data.append(TagTIRData(tagName: tagName, tir: tir, count: tagRecords.count))
        }
        
        return snapshot(content: {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(data) { item in
                    HStack(spacing: 8) {
                        Text(item.tagName)
                            .font(.system(size: 11))
                            .frame(width: 80, alignment: .leading)
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 16)
                                
                                Rectangle()
                                    .fill(item.tir >= 70 ? Color.green : Color.orange)
                                    .frame(width: geometry.size.width * item.tir / 100, height: 16)
                            }
                            .cornerRadius(4)
                        }
                        
                        Text(String(format: "%.0f%%", item.tir))
                            .font(.system(size: 11, weight: .medium))
                            .frame(width: 45, alignment: .trailing)
                    }
                    .frame(height: 20)
                }
            }
            .padding(16)
            .frame(width: size.width, height: size.height)
            .background(Color.white)
        }, size: size)
    }
    
    /// 渲染 TAR/TIR/TBR 堆叠条
    /// - Parameters:
    ///   - records: 血糖记录
    ///   - settings: 用户设置
    ///   - size: 图片尺寸
    /// - Returns: 堆叠条图片
    static func renderRangeDistributionBar(
        records: [GlucoseRecord],
        settings: UserSettings,
        size: CGSize = CGSize(width: 250, height: 100)
    ) -> UIImage? {
        let tbr = GlucoseCalculator.contextualTimeBelowRange(records: records, settings: settings)
        let tir = GlucoseCalculator.contextualTimeInRange(records: records, settings: settings)
        let tar = GlucoseCalculator.contextualTimeAboveRange(records: records, settings: settings)
        
        return snapshot(content: {
            VStack(spacing: 12) {
                Text(String(localized: "statistics.glucose_distribution"))
                    .font(.system(size: 13, weight: .semibold))
                
                HStack(spacing: 0) {
                    if tbr > 0 {
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: size.width * 0.8 * tbr / 100)
                    }
                    if tir > 0 {
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: size.width * 0.8 * tir / 100)
                    }
                    if tar > 0 {
                        Rectangle()
                            .fill(Color.orange)
                            .frame(width: size.width * 0.8 * tar / 100)
                    }
                }
                .frame(height: 24)
                .cornerRadius(6)
                
                HStack(spacing: 8) {
                    Label(String(format: "%.0f%%", tbr), systemImage: "arrow.down.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.red)
                    Label(String(format: "%.0f%%", tir), systemImage: "checkmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.green)
                    Label(String(format: "%.0f%%", tar), systemImage: "arrow.up.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.orange)
                }
            }
            .padding(16)
            .frame(width: size.width, height: size.height)
            .background(Color.white)
        }, size: size)
    }
    
    /// 渲染各场景箱线图（简化版）
    /// - Parameters:
    ///   - records: 血糖记录
    ///   - settings: 用户设置
    ///   - size: 图片尺寸
    /// - Returns: 箱线图图片
    static func renderBoxPlotChart(
        records: [GlucoseRecord],
        settings: UserSettings,
        size: CGSize = CGSize(width: 515, height: 220)
    ) -> UIImage? {
        let byTag = Dictionary(grouping: records) { $0.sceneTagId }
        let sortedTags = byTag.sorted { $0.value.count > $1.value.count }
        
        struct BoxPlotData: Identifiable {
            let id = UUID()
            let tagName: String
            let min: Double
            let q1: Double
            let median: Double
            let q3: Double
            let max: Double
            let targetLow: Double
            let targetHigh: Double
        }
        
        var data: [BoxPlotData] = []
        for (tagId, tagRecords) in sortedTags.prefix(6) {
            guard tagRecords.count >= 3 else { continue }
            
            let tagName = settings.displayName(for: tagId)
            let range = settings.thresholdRange(for: tagId)
            let sorted = tagRecords.map(\.value).sorted()
            let count = sorted.count
            
            let median: Double
            let q1: Double
            let q3: Double
            
            if count == 3 {
                median = sorted[1]
                q1 = sorted[0]
                q3 = sorted[2]
            } else {
                median = count % 2 == 0 ? (sorted[count/2-1] + sorted[count/2]) / 2.0 : sorted[count/2]
                q1 = sorted[count/4]
                q3 = sorted[count*3/4]
            }
            
            data.append(BoxPlotData(
                tagName: tagName,
                min: sorted.first ?? 0,
                q1: q1,
                median: median,
                q3: q3,
                max: sorted.last ?? 0,
                targetLow: range.low,
                targetHigh: range.high
            ))
        }
        
        guard !data.isEmpty else { return nil }
        
        let allValues = data.flatMap { [$0.min, $0.max] }
        let globalMin = allValues.min() ?? 0
        let globalMax = allValues.max() ?? 15
        let valueRange = globalMax - globalMin
        
        return snapshot(content: {
            VStack(spacing: 6) {
                ForEach(data) { item in
                    HStack(spacing: 8) {
                        Text(item.tagName)
                            .font(.system(size: 10))
                            .frame(width: 70, alignment: .leading)
                        
                        GeometryReader { geometry in
                            let width = geometry.size.width
                            
                            ZStack(alignment: .leading) {
                                // 目标区域背景
                                Rectangle()
                                    .fill(Color.green.opacity(0.1))
                                    .frame(
                                        width: width * (item.targetHigh - item.targetLow) / valueRange,
                                        height: 20
                                    )
                                    .offset(x: width * (item.targetLow - globalMin) / valueRange)
                                
                                // 最小到最大的线
                                Rectangle()
                                    .fill(Color.gray)
                                    .frame(
                                        width: width * (item.max - item.min) / valueRange,
                                        height: 1
                                    )
                                    .offset(x: width * (item.min - globalMin) / valueRange)
                                
                                // Q1 到 Q3 的箱体
                                Rectangle()
                                    .fill(Color.blue.opacity(0.3))
                                    .stroke(Color.blue, lineWidth: 1)
                                    .frame(
                                        width: width * (item.q3 - item.q1) / valueRange,
                                        height: 16
                                    )
                                    .offset(x: width * (item.q1 - globalMin) / valueRange)
                                
                                // 中位数线
                                Rectangle()
                                    .fill(Color.blue)
                                    .frame(width: 2, height: 16)
                                    .offset(x: width * (item.median - globalMin) / valueRange)
                            }
                        }
                        .frame(height: 22)
                        
                        Text(String(format: "%.1f", item.median))
                            .font(.system(size: 9))
                            .frame(width: 35, alignment: .trailing)
                    }
                }
            }
            .padding(16)
            .frame(width: size.width, height: size.height)
            .background(Color.white)
        }, size: size)
    }
}
