import Foundation
import NetworkExtension

extension NEIPv4Route {
    static func from(_ cidr: String) -> NEIPv4Route? {
        let parts = cidr.split(separator: "/")
        guard parts.count == 2,
              let prefix = Int(parts[1]),
              let address = String(parts[0]).asIPv4Address else { return nil }
        let mask = ipv4Mask(from: prefix)
        return NEIPv4Route(destinationAddress: address, subnetMask: mask)
    }

    private static func ipv4Mask(from prefix: Int) -> String {
        let mask: UInt32 = prefix == 0 ? 0 : ~((1 << (32 - prefix)) - 1)
        return String(
            format: "%d.%d.%d.%d",
            (mask >> 24) & 0xFF,
            (mask >> 16) & 0xFF,
            (mask >> 8) & 0xFF,
            mask & 0xFF
        )
    }
}

extension NEIPv6Route {
    static func from(_ cidr: String) -> NEIPv6Route? {
        let parts = cidr.split(separator: "/")
        guard parts.count == 2,
              let prefix = UInt8(parts[1]) else { return nil }
        return NEIPv6Route(destinationAddress: String(parts[0]), networkPrefixLength: NSNumber(value: prefix))
    }
}

private extension String {
    var asIPv4Address: String? {
        let octets = split(separator: ".")
        guard octets.count == 4,
              octets.allSatisfy({ UInt8($0) != nil }) else { return nil }
        return self
    }
}
