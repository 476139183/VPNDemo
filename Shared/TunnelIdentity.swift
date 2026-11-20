import Foundation

enum TunnelIdentity {
    /// 与主 App PRODUCT_BUNDLE_IDENTIFIER 保持一致
    static let appBundleId = "com.languageclass"
    static let tunnelBundleId = "com.languageclass.PacketTunnel"
    static let appGroupId = "group.com.languageclass.vpndemo"

    enum ConfigKey {
        static let mode = "mode"
        static let serverAddress = "serverAddress"
        static let serverPort = "serverPort"
        static let serverName = "serverName"
        static let isDemo = "isDemo"
        static let mtu = "mtu"
        static let dnsServers = "dnsServers"
        static let tunnelIPv4 = "tunnelIPv4"
        static let tunnelSubnet = "tunnelSubnet"
        static let includedCIDRs = "includedCIDRs"
        static let excludedCIDRsFile = "excluded_cidrs.txt"
        static let bytesSent = "bytesSent"
        static let bytesReceived = "bytesReceived"
    }

    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupId)
    }

    static var sharedContainerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
    }
}
