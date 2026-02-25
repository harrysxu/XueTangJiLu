//
//  Date+Helpers.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import Foundation

extension Date {

    /// 相对时间描述（如 "20 分钟前"、"2 小时前"、"昨天"）
    var relativeDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale.current
        return formatter.localizedString(for: self, relativeTo: .now)
    }

    /// 格式化为 "HH:mm"
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }

    /// 格式化为 "yyyy年M月d日 HH:mm"
    var fullDateTimeString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    /// 格式化为 "M月d日"
    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self)
    }
    
    /// 格式化为 "yyyy年M月d日"
    var mediumDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .medium
        return formatter.string(from: self)
    }

    /// 格式化为日期范围字符串
    static func rangeString(from start: Date, to end: Date) -> String {
        "\(start.shortDateString) - \(end.shortDateString)"
    }

    /// 判断是否为今天
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// 判断是否为昨天
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    /// 获取日期分组标题（"今日"、"昨日"、"M月d日"）
    var sectionTitle: String {
        if isToday {
            return String(localized: "today.records")
        } else if isYesterday {
            return String(localized: "yesterday.records")
        } else {
            return shortDateString
        }
    }

    /// 获取一天的开始时间
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// N 天前的日期
    static func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
    }
}
