import Testing

@testable import LeashCore

struct AddressScopeTests {
    @Test(arguments: [
        "192.168.100.1", "10.0.0.5", "172.16.0.1", "172.31.255.255", "169.254.10.1", "127.0.0.1",
        "224.0.0.251", "255.255.255.255", "::1", "fe80::1", "fd00::1", "ff02::fb",
    ])
    func localAddresses(_ address: String) {
        #expect(addressScope(of: address) == .local)
    }

    @Test(arguments: ["172.32.0.1", "100.64.0.1", "160.79.104.10", "8.8.8.8", "2a00:1450:4006:80b::200e"])
    func internetAddresses(_ address: String) {
        #expect(addressScope(of: address) == .internet)
    }

    @Test func scopedAndMappedAddressesAreClassified() {
        #expect(addressScope(of: "fe80::1%en0") == .local)
        #expect(addressScope(of: "::ffff:192.168.1.5") == .local)
        #expect(addressScope(of: "::ffff:8.8.8.8") == .internet)
    }

    @Test(arguments: ["", "nonsense", "300.1.1.1", "1.2.3.4.5"])
    func garbageIsRejected(_ text: String) {
        #expect(addressScope(of: text) == nil)
    }

    @Test func localNetworkListHasEveryLocalRange() {
        #expect(
            LocalNetworks.all.map { "\($0.address)/\($0.prefix)" } == [
                "10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16", "169.254.0.0/16", "127.0.0.0/8", "224.0.0.0/4",
                "255.255.255.255/32", "::1/128", "fe80::/10", "fc00::/7", "ff00::/8",
            ])
    }
}
