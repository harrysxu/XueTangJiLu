//
//  AppLogger.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/26.
//

import Foundation
import os.log

/// 应用日志工具
enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.xxl.XueTangJiLu"
    
    static let cloudKit = Logger(subsystem: subsystem, category: "CloudKit")
    static let sync = Logger(subsystem: subsystem, category: "Sync")
    static let deduplication = Logger(subsystem: subsystem, category: "Deduplication")
    static let notification = Logger(subsystem: subsystem, category: "Notification")
    static let healthKit = Logger(subsystem: subsystem, category: "HealthKit")
    static let general = Logger(subsystem: subsystem, category: "General")
    
    /// 仅在 DEBUG 模式下打印
    static func debug(_ message: String, category: Logger = AppLogger.general) {
        #if DEBUG
        category.debug("\(message)")
        #endif
    }
    
    /// 信息级别日志
    static func info(_ message: String, category: Logger = AppLogger.general) {
        category.info("\(message)")
    }
    
    /// 警告级别日志
    static func warning(_ message: String, category: Logger = AppLogger.general) {
        category.warning("\(message)")
    }
    
    /// 错误级别日志
    static func error(_ message: String, category: Logger = AppLogger.general) {
        category.error("\(message)")
    }
}
