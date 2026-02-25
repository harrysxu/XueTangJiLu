//
//  CKError+Extensions.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/22.
//

import Foundation
import CloudKit

extension CKError {
    
    /// 用户友好的错误描述
    var userFriendlyMessage: String {
        switch self.code {
        case .notAuthenticated:
            return "请在系统设置中登录 iCloud"
            
        case .networkUnavailable, .networkFailure:
            return "网络连接失败，请检查网络设置"
            
        case .quotaExceeded:
            return "iCloud 存储空间不足，请清理空间或升级容量"
            
        case .limitExceeded:
            return "操作超出限制，请稍后重试"
            
        case .serverResponseLost, .serviceUnavailable:
            return "iCloud 服务暂时不可用，请稍后重试"
            
        case .requestRateLimited:
            return "操作过于频繁，请稍后重试"
            
        case .partialFailure:
            return "部分数据同步失败"
            
        case .incompatibleVersion:
            return "数据版本不兼容，请更新应用"
            
        case .constraintViolation:
            return "数据冲突，已自动处理"
            
        case .permissionFailure:
            return "缺少必要的 iCloud 权限"
            
        case .zoneNotFound:
            return "同步区域未找到，正在重新初始化"
            
        case .serverRecordChanged:
            return "数据已在其他设备更新"
            
        default:
            return "同步时发生错误: \(self.localizedDescription)"
        }
    }
    
    /// 是否可以自动重试
    var shouldRetry: Bool {
        switch self.code {
        case .networkUnavailable, .networkFailure, .serviceUnavailable, 
             .serverResponseLost, .zoneBusy, .requestRateLimited:
            return true
        default:
            return false
        }
    }
    
    /// 是否需要用户操作
    var requiresUserAction: Bool {
        switch self.code {
        case .notAuthenticated, .quotaExceeded, .permissionFailure, .incompatibleVersion:
            return true
        default:
            return false
        }
    }
}
