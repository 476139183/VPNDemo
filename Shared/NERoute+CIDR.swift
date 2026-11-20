import Foundation
import NetworkExtension

extension NEIPv4Route {
    static func fromCIDR(_ cidr: String) -> NEIPv4Route? {
        let parts = cidr.split(separator: "/")
        guard parts.count == 2,
              let prefix = Int(parts[1]),
              prefix >= 0, prefix <= 32 else { return nil }
        let address = String(parts[0])
        guard address.isIPv4Address else { return nil }
        return NEIPv4Route(destinationAddress: address, subnetMask: ipv4Mask(from: prefix))
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

extension String {
    var isIPv4Address: Bool {
        let octets = split(separator: ".")
        guard octets.count == 4 else { return false }
        return octets.allSatisfy { UInt8($0) != nil }
    }
}
