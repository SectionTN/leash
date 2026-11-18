import Foundation
import Testing

@testable import LeashCore

struct PlanTests {
    let tunis = calendar("Africa/Tunis")

    func monthly(_ cal: Calendar, start: String = "2026-11-16") -> Plan {
        Plan(name: "Home 4G", size: 30 * .gigabyte, periodDays: 30, startDay: calendarDay(start))
    }

    @Test func periodRunsThirtyDaysFromTheStartDay() {
        let period = monthly(tunis).period(containing: day("2026-11-18 10:00", tunis), calendar: tunis)
        #expect(period == PlanPeriod(start: day("2026-11-16", tunis), end: day("2026-12-16", tunis)))
    }

    @Test func nextPeriodStartsWhenTheFirstEnds() {
        let period = monthly(tunis).period(containing: day("2026-12-16", tunis), calendar: tunis)
        #expect(period == PlanPeriod(start: day("2026-12-16", tunis), end: day("2027-01-15", tunis)))
    }

    @Test func allowanceSplitsWhatIsLeftOverTheDaysLeft() {
        let plan = monthly(tunis)
        let today = day("2026-11-18 10:00", tunis)
        #expect(plan.daysLeft(on: today, calendar: tunis) == 28)
        #expect(plan.dailyAllowance(usedBeforeToday: 10 * .gigabyte, on: today, calendar: tunis) == 714_285_714)
    }

    @Test func overusedPlanGivesZeroAllowance() {
        let today = day("2026-11-18", tunis)
        #expect(monthly(tunis).dailyAllowance(usedBeforeToday: 31 * .gigabyte, on: today, calendar: tunis) == 0)
    }

    @Test func dailyBundleGetsItsWholeSizeEveryDay() {
        let plan = Plan(name: "Daily", size: 1 * .gigabyte, periodDays: 1, startDay: calendarDay("2026-11-01"))
        #expect(plan.dailyAllowance(usedBeforeToday: 0, on: day("2026-11-18", tunis), calendar: tunis) == .gigabyte)
    }

    @Test func zeroPeriodIsTreatedAsOneDay() {
        let plan = Plan(name: "Bad", size: .gigabyte, periodDays: 0, startDay: calendarDay("2026-11-01"))
        #expect(plan.periodDays == 1)
    }

    @Test func dayBeforeStartBelongsToFirstPeriod() {
        let plan = monthly(tunis)
        let early = day("2026-11-14", tunis)
        #expect(plan.period(containing: early, calendar: tunis).start == day("2026-11-16", tunis))
        #expect(plan.daysLeft(on: early, calendar: tunis) == 32)
        #expect(plan.dailyAllowance(usedBeforeToday: 0, on: early, calendar: tunis) == 937_500_000)
    }

    @Test func allowanceCountsCalendarDaysAcrossDaylightSaving() {
        let paris = calendar("Europe/Paris")
        let plan = monthly(paris, start: "2026-03-20")
        #expect(plan.daysLeft(on: day("2026-03-28", paris), calendar: paris) == 22)
        #expect(plan.daysLeft(on: day("2026-03-30", paris), calendar: paris) == 20)
        #expect(plan.period(containing: day("2026-03-28", paris), calendar: paris).end == day("2026-04-19", paris))
    }

    @Test func startDayStaysTheSameCalendarDayInAnotherTimeZone() {
        let plan = monthly(tunis)
        let newYork = calendar("America/New_York")
        let period = plan.period(containing: day("2026-12-15 12:00", newYork), calendar: newYork)
        #expect(period.start == day("2026-11-16", newYork))
        #expect(plan.daysLeft(on: day("2026-11-18", newYork), calendar: newYork) == 28)
    }

    @Test func unitsAreDecimal() {
        #expect(Bytes.megabyte == 1_000_000)
        #expect(Bytes.gigabyte == 1_000_000_000)
        #expect(Bytes.defaultTopUp == 200_000_000)
    }
}
