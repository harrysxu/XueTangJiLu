//
//  NetworkMonitor.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/22.
//

import Foundation
import Network

/// 网络连接状态监控器
@Observable
final class NetworkMonitor {
    
    // MARK: - Properties
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.xxl.xuetangjilu.network-monitor")
    
    /// 是否有网络连接
    var isConnected: Bool = true
    
    /// 是否使用WiFi
    var isUsingWiFi: Bool = false
    
    /// 是否使用蜂窝网络
    var isUsingCellular: Bool = false
    
    /// 网络类型描述
    var connectionType: String {
        if !isConnected {
            return "离线"
        } else if isUsingWiFi {
            return "WiFi"
        } else if isUsingCellular {
            return "蜂窝网络"
        } else {
            return "其他"
        }
    }
    
    // MARK: - Initialization
    
    init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Methods
    
    /// 开始监控网络状态
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            Task { @MainActor in
                self.isConnected = path.status == .satisfied
                self.isUsingWiFi = path.usesInterfaceType(.wifi)
                self.isUsingCellular = path.usesInterfaceType(.cellular)
            }
        }
        
        monitor.start(queue: queue)
    }
    
    /// 停止监控
    func stopMonitoring() {
        monitor.cancel()
    }
}
