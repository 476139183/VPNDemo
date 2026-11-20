import Foundation

enum VPNStatus: String {
    case disconnected = "disconnected"
    case connecting = "connecting"
    case connected = "connected"
    case disconnecting = "disconnecting"
    case invalid = "invalid"

    var displayText: String {
        switch self {
        case .disconnected:
            return "未连接"
        case .connecting:
            return "连接中..."
        case .connected:
            return "已连接"
        case .disconnecting:
            return "断开中..."
        case .invalid:
            return "配置无效"
        }
    }

    var buttonText: String {
        switch self {
        case .disconnected, .invalid:
            return "连接"
        case .connecting:
            return "连接中..."
        case .connected:
            return "断开"
        case .disconnecting:
            return "断开中..."
        }
    }
}

struct VPNConnectionInfo {
    var status: VPNStatus
    var connectedServer: ServerNode?
    var connectedDate: Date?
    var bytesReceived: Int64
    var bytesSent: Int64

    var duration: TimeInterval {
        guard let date = connectedDate, status == .connected else { return 0 }
        return Date().timeIntervalSince(date)
    }

    var durationText: String {
        let total = Int(duration)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    var downloadSpeedText: String {
        return ByteCountFormatter.string(fromByteCount: bytesReceived, countStyle: .binary)
    }

    var uploadSpeedText: String {
        return ByteCountFormatter.string(fromByteCount: bytesSent, countStyle: .binary)
    }

    static let initial = VPNConnectionInfo(
        status: .disconnected,
        connectedServer: nil,
        connectedDate: nil,
        bytesReceived: 0,
        bytesSent: 0
    )
}
