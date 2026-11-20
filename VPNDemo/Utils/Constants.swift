import UIKit

enum AppColors {
    static let background = UIColor(hex: "#0D1117")
    static let cardBackground = UIColor(hex: "#161B22")
    static let primary = UIColor(hex: "#238636")
    static let primaryHighlight = UIColor(hex: "#2EA043")
    static let textPrimary = UIColor(hex: "#F0F6FC")
    static let textSecondary = UIColor(hex: "#8B949E")
    static let border = UIColor(hex: "#30363D")
    static let error = UIColor(hex: "#F85149")
    static let success = UIColor(hex: "#3FB950")
    static let warning = UIColor(hex: "#D29922")
}

enum AppFonts {
    static func bold(size: CGFloat) -> UIFont {
        return .systemFont(ofSize: size, weight: .bold)
    }

    static func semibold(size: CGFloat) -> UIFont {
        return .systemFont(ofSize: size, weight: .semibold)
    }

    static func regular(size: CGFloat) -> UIFont {
        return .systemFont(ofSize: size, weight: .regular)
    }

    static func medium(size: CGFloat) -> UIFont {
        return .systemFont(ofSize: size, weight: .medium)
    }
}

enum AppConstants {
    static let cornerRadius: CGFloat = 12
    static let smallCornerRadius: CGFloat = 8
    static let largeCornerRadius: CGFloat = 16

    static let animationDuration: TimeInterval = 0.3

    enum UserDefaultsKeys {
        static let selectedServerId = "selectedServerId"
        static let selectedMode = "selectedMode"
        static let autoConnect = "autoConnect"
        static let isFirstLaunch = "isFirstLaunch"
        static let customServerNodes = "customServerNodes"
        static let savedRules = "savedRules"
        /// 显式开关；未设置时自动判断（非 example 域名 + Keychain 有密钥）
        static let useRealVPN = "useRealVPN"
    }

    enum KeychainKeys {
        static let vpnPrivateKey = "vpnPrivateKey"
        static let vpnPublicKey = "vpnPublicKey"
    }
}
