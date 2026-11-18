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

    /// Goes through the byte init, so a decoded MAC is checked and written the same way.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let mac = try container.decode(String.self, forKey: .gatewayMAC)
        let parts = mac.split(separator: ":", omittingEmptySubsequences: false)
        let bytes = parts.compactMap { $0.count == 2 && $0.allSatisfy(\.isHexDigit) ? UInt8($0, radix: 16) : nil }
        let type = try container.decode(InterfaceType.self, forKey: .interfaceType)
        guard parts.count == bytes.count, let network = NetworkID(interfaceType: type, gatewayMACBytes: bytes) else {
            throw DecodingError.dataCorruptedError(forKey: .gatewayMAC, in: container, debugDescription: mac)
        }
        self = network
    }

    private enum CodingKeys: String, CodingKey {
        case interfaceType, gatewayMAC
    }
}
