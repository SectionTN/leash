import Testing

@testable import LeashCore

struct DecisionTests {
    let fresh = UsageContext(
        todayBytes: 100 * .megabyte, todayLimit: .gigabyte, appTodayBytes: 10 * .megabyte, appLimit: nil)
    let spent = UsageContext(todayBytes: .gigabyte, todayLimit: .gigabyte, appTodayBytes: 10 * .megabyte, appLimit: nil)

    @Test func offThePlanEverythingPasses() {
        #expect(decide(state: nil, onPlan: false, usage: spent) == .pass)
        #expect(decide(state: .blocked, onPlan: false, usage: spent) == .pass)
    }

    @Test func unknownAndBlockedAppsAreDropped() {
        #expect(decide(state: nil, onPlan: true, usage: fresh) == .drop(.unknown))
        #expect(decide(state: .blocked, onPlan: true, usage: fresh) == .drop(.blocked))
    }

    @Test func allowedAppsAreWatchedUntilTheAllowanceRunsOut() {
        #expect(decide(state: .allowed, onPlan: true, usage: fresh) == .watch)
        #expect(decide(state: .allowed, onPlan: true, usage: spent) == .drop(.allowance))
    }

    @Test func essentialAppsOutliveTheAllowance() {
        #expect(decide(state: .essential, onPlan: true, usage: spent) == .watch)
    }

    @Test func appLimitStopsEvenEssentialApps() {
        var usage = fresh
        usage.appLimit = 500 * .megabyte
        usage.appTodayBytes = 500 * .megabyte
        #expect(decide(state: .essential, onPlan: true, usage: usage) == .drop(.appLimit))
        #expect(decide(state: .allowed, onPlan: true, usage: usage) == .drop(.appLimit))
        usage.appTodayBytes = 499 * .megabyte
        #expect(decide(state: .essential, onPlan: true, usage: usage) == .watch)
    }

    @Test func topUpsRaiseTheLimitsTheyArePartOf() {
        let topped = UsageContext(
            todayBytes: .gigabyte, todayLimit: .gigabyte + .defaultTopUp, appTodayBytes: 0, appLimit: nil)
        #expect(decide(state: .allowed, onPlan: true, usage: topped) == .watch)
    }
}
