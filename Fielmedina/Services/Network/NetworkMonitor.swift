//
//  NetworkMonitor.swift
//  Fielmedina
//
//  Created by Aslan on 2/2/26.
//

import Network
import Foundation

/// Global network connectivity monitor using NWPathMonitor.
/// Thread-safe usage: `NetworkMonitor.shared.isConnected`
final class NetworkMonitor: @unchecked Sendable {
    static let shared = NetworkMonitor()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.fielmedina.networkmonitor", attributes: .concurrent)
    private var _isConnected: Bool = true
    
    var isConnected: Bool {
        queue.sync { _isConnected }
    }
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            let nextStatus = (path.status == .satisfied)
            self.queue.async(flags: .barrier) {
                guard self._isConnected != nextStatus else { return }
                self._isConnected = nextStatus
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .networkStatusChanged,
                        object: nil,
                        userInfo: ["isConnected": nextStatus]
                    )
                }
            }
        }
        monitor.start(queue: DispatchQueue(label: "monitor.queue"))
    }
}

extension Notification.Name {
    static let networkStatusChanged = Notification.Name("network_status_changed")
}
