import Network

public enum AddressScope: Equatable, Sendable {
    case local, internet
}

public struct IPNetwork: Hashable, Sendable {
    public let address: String
    public let prefix: Int
}

/// Address ranges that never leave the local network. CGNAT `100.64.0.0/10` is not one: it is on the carrier's side.
public enum LocalNetworks {
    public static let all: [IPNetwork] = [
        IPNetwork(address: "10.0.0.0", prefix: 8),
        IPNetwork(address: "172.16.0.0", prefix: 12),
        IPNetwork(address: "192.168.0.0", prefix: 16),
        IPNetwork(address: "169.254.0.0", prefix: 16),
        IPNetwork(address: "127.0.0.0", prefix: 8),
        IPNetwork(address: "224.0.0.0", prefix: 4),
        IPNetwork(address: "255.255.255.255", prefix: 32),
        IPNetwork(address: "0.0.0.0", prefix: 8),
        IPNetwork(address: "::1", prefix: 128),
        IPNetwork(address: "::", prefix: 128),
        IPNetwork(address: "fe80::", prefix: 10),
        IPNetwork(address: "fc00::", prefix: 7),
        IPNetwork(address: "ff00::", prefix: 8),
    ]

    fileprivate static let ranges: [(base: [UInt8], prefix: Int)] = all.compactMap { network in
        addressBytes(network.address).map { (base: $0, prefix: network.prefix) }
    }
}

/// Classifies an IP address literal, or returns nil when the text isn't one.
public func addressScope(of address: String) -> AddressScope? {
    guard let bytes = addressBytes(address) else { return nil }
    let isLocal = LocalNetworks.ranges.contains { range in
        range.base.count == bytes.count && hasPrefix(bytes, range.base, bits: range.prefix)
    }
    return isLocal ? .local : .internet
}

/// The address's bytes, with a zone suffix dropped and an IPv4-mapped IPv6 address reduced to its IPv4 bytes.
private func addressBytes(_ text: String) -> [UInt8]? {
    let parts = text.split(separator: "%", maxSplits: 1, omittingEmptySubsequences: false)
    let host = String(parts[0])
    if parts.count == 2 {
        // Only an IPv6 address takes a zone, and the zone is one non-empty name.
        guard host.contains(":"), !parts[1].isEmpty, !parts[1].contains("%") else { return nil }
    }
    guard host.contains(":") else { return dottedQuad(host) }
    guard let v6 = IPv6Address(host) else { return nil }
    let bytes = Array(v6.rawValue)
    let isMapped = bytes[0..<10].allSatisfy { $0 == 0 } && bytes[10] == 0xff && bytes[11] == 0xff
    return isMapped ? Array(bytes[12...]) : bytes
}

/// Four decimal numbers from 0 to 255 without leading zeros. Shorthand, octal and hex forms are rejected.
private func dottedQuad(_ text: String) -> [UInt8]? {
    let parts = text.split(separator: ".", omittingEmptySubsequences: false)
    guard parts.count == 4 else { return nil }
    var bytes: [UInt8] = []
    for part in parts {
        guard (1...3).contains(part.count),
            part.utf8.allSatisfy({ (UInt8(ascii: "0")...UInt8(ascii: "9")).contains($0) }),
            part.count == 1 || part.first != "0", let byte = UInt8(part)
        else { return nil }
        bytes.append(byte)
    }
    return bytes
}

private func hasPrefix(_ bytes: [UInt8], _ base: [UInt8], bits: Int) -> Bool {
    var remaining = bits
    for (byte, baseByte) in zip(bytes, base) where remaining > 0 {
        let mask: UInt8 = remaining >= 8 ? 0xff : ~(0xff >> UInt8(remaining))
        if byte & mask != baseByte & mask { return false }
        remaining -= 8
    }
    return true
}
