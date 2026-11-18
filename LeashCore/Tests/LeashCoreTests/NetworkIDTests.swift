import Foundation
import Testing

@testable import LeashCore

struct NetworkIDTests {
    let router = NetworkID(interfaceType: .wifi, gatewayMACBytes: [0x7e, 0x18, 0x6a, 0xc2, 0x04, 0x27])!

    @Test func macIsLowercaseAndZeroPadded() {
        #expect(router.gatewayMAC == "7e:18:6a:c2:04:27")
    }

    @Test func wrongLengthOrZeroMacIsRejected() {
        #expect(NetworkID(interfaceType: .wifi, gatewayMACBytes: [1, 2, 3, 4, 5]) == nil)
        #expect(NetworkID(interfaceType: .wifi, gatewayMACBytes: [0, 0, 0, 0, 0, 0]) == nil)
    }

    @Test func onePlanCoversSeveralNetworks() {
        let hotspot = NetworkID(interfaceType: .wifi, gatewayMACBytes: [0x02, 0, 0, 0, 0, 0x01])!
        let elsewhere = NetworkID(interfaceType: .wired, gatewayMACBytes: [0x02, 0, 0, 0, 0, 0x02])!
        let plan = Plan(
            name: "SIM", size: 30 * .gigabyte, periodDays: 30, startDay: calendarDay("2026-11-16"),
            networks: [router, hotspot])
        #expect(plan.covers(router))
        #expect(plan.covers(hotspot))
        #expect(!plan.covers(elsewhere))
    }

    @Test func sameMacOnAnotherInterfaceTypeIsAnotherNetwork() {
        let wired = NetworkID(interfaceType: .wired, gatewayMACBytes: [0x7e, 0x18, 0x6a, 0xc2, 0x04, 0x27])!
        #expect(wired != router)
    }
}
