import Foundation
import Testing

@testable import LeashCore

struct UsageLedgerTests {
    let cal = calendar("Africa/Tunis")
    let plan = UUID()
    let claude = AppKey.signed(team: "Q6L2SF6YDW", identifier: "com.anthropic.claude-code")
    let curl = AppKey.named("curl")

    @Test func recordsInOneHourShareABucket() {
        var ledger = UsageLedger()
        ledger.record(
            app: claude, planID: plan, bytesIn: 1, bytesOut: 10, at: day("2026-11-18 10:05", cal), calendar: cal)
        ledger.record(
            app: claude, planID: plan, bytesIn: 2, bytesOut: 20, at: day("2026-11-18 10:55", cal), calendar: cal)
        let hour = ledger.totals(planID: plan, from: day("2026-11-18 10:00", cal), to: day("2026-11-18 11:00", cal))
        #expect(hour == UsageTotals(bytesIn: 3, bytesOut: 30))
    }

    @Test func todayExcludesYesterdayAndOtherPlans() {
        var ledger = UsageLedger()
        ledger.record(
            app: claude, planID: plan, bytesIn: 0, bytesOut: 500, at: day("2026-11-17 23:30", cal), calendar: cal)
        ledger.record(
            app: claude, planID: plan, bytesIn: 0, bytesOut: 70, at: day("2026-11-18 00:10", cal), calendar: cal)
        ledger.record(
            app: claude, planID: UUID(), bytesIn: 0, bytesOut: 9, at: day("2026-11-18 01:00", cal), calendar: cal)
        let today = ledger.totals(planID: plan, from: day("2026-11-18", cal), to: day("2026-11-19", cal))
        #expect(today.total == 70)
    }

    @Test func rankingPutsTheBiggestAppFirst() {
        var ledger = UsageLedger()
        let at = day("2026-11-18 12:00", cal)
        ledger.record(app: curl, planID: plan, bytesIn: 40, bytesOut: 0, at: at, calendar: cal)
        ledger.record(app: claude, planID: plan, bytesIn: 5, bytesOut: 300, at: at, calendar: cal)
        let ranking = ledger.ranking(planID: plan, from: day("2026-11-18", cal), to: day("2026-11-19", cal))
        #expect(ranking.map(\.app) == [claude, curl])
        #expect(
            ledger.totals(planID: plan, app: curl, from: day("2026-11-18", cal), to: day("2026-11-19", cal)).total == 40
        )
    }

    @Test func pruneDropsOnlyOlderBuckets() {
        var ledger = UsageLedger()
        ledger.record(app: curl, planID: plan, bytesIn: 1, bytesOut: 0, at: day("2025-10-01", cal), calendar: cal)
        ledger.record(app: curl, planID: plan, bytesIn: 2, bytesOut: 0, at: day("2026-11-18", cal), calendar: cal)
        ledger.prune(before: day("2025-10-14", cal))
        #expect(ledger.totals(planID: plan, from: .distantPast, to: .distantFuture).bytesIn == 2)
    }
}
