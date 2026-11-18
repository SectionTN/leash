public enum InterfaceType: String, Codable, Sendable {
    case wifi, wired, cellular, other
}

/// A network, known by the interface type and the MAC address of its default gateway.
public struct NetworkID: Hashable, Codable, Sendable {
    public let interfaceType: InterfaceType
    /// Lowercase, colon-separated, two digits per byte.
    public let gatewayMAC: String

    public init?(interfaceType: InterfaceType, gatewayMACBytes: [UInt8]) {
        guard gatewayMACBytes.count == 6, gatewayMACBytes.contains(where: { $0 != 0 }) else { return nil }
        self.interfaceType = interfaceType
        self.gatewayMAC = gatewayMACBytes.map { byte in
            let hex = String(byte, radix: 16)
            return byte < 0x10 ? "0" + hex : hex
        }.joined(separator: ":")
    }
}
