import Foundation
import Testing

@testable import LeashCore

struct AlertsTests {
    let start = Date(timeIntervalSince1970: 1_795_000_000)
    let steam = AppKey.named("steam")
    let update = AppKey.signed(team: "apple", identifier: "com.apple.softwareupdated")

    @Test func firstBlockIsDeliveredAtOnceThenBatched() {
        var digest = BlockedDigest()
        digest.noteBlocked(steam, at: start)
        #expect(digest.takeDigest(at: start) == [steam])
        digest.noteBlocked(update, at: start + 60)
        #expect(digest.takeDigest(at: start + 60) == nil)
        #expect(digest.takeDigest(at: start + 600) == [update])
        #expect(digest.takeDigest(at: start + 700) == nil)
    }

    @Test func repeatedBlocksCollapseIntoOneDigest() {
        var digest = BlockedDigest()
        for second in 0..<50 { digest.noteBlocked(steam, at: start + Double(second)) }
        #expect(digest.takeDigest(at: start + 50) == [steam])
        #expect(digest.takeDigest(at: start + 51) == nil)
    }

    @Test func appThatKeepsRetryingIsAnnouncedOnce() {
        var digest = BlockedDigest()
        var summaries = 0
        for minute in 0..<60 {
            let now = start + Double(minute * 60)
            digest.noteBlocked(update, at: now)
            if digest.takeDigest(at: now) != nil { summaries += 1 }
        }
        #expect(summaries == 1)
    }

    @Test func forgottenAppIsAnnouncedAgain() {
        var digest = BlockedDigest()
        digest.noteBlocked(steam, at: start)
        #expect(digest.takeDigest(at: start) == [steam])
        digest.forget(steam)
        digest.noteBlocked(steam, at: start + 600)
        #expect(digest.takeDigest(at: start + 600) == [steam])
    }

    @Test func clockSetBackDoesNotSilenceTheDigest() {
        var digest = BlockedDigest()
        digest.noteBlocked(steam, at: start)
        #expect(digest.takeDigest(at: start) == [steam])
        digest.noteBlocked(update, at: start - 3600)
        #expect(digest.takeDigest(at: start - 3600) == [update])
    }

    @Test func lastAttemptKeepsUpdatingAfterTheAppIsAnnounced() {
        var digest = BlockedDigest()
        digest.noteBlocked(steam, at: start)
        #expect(digest.takeDigest(at: start) == [steam])
        digest.noteBlocked(steam, at: start + 300)
        #expect(digest.lastAttempts == [steam: start + 300])
    }

    @Test func forgottenAppHasNoLastAttempt() {
        var digest = BlockedDigest()
        digest.noteBlocked(steam, at: start)
        digest.forget(steam)
        #expect(digest.lastAttempts.isEmpty)
    }

    @Test func thresholdsFireOnTheWayUp() {
        let limit = 1000 * Bytes.megabyte
        #expect(crossedThreshold(before: 790 * .megabyte, after: 810 * .megabyte, limit: limit) == .eightyPercent)
        #expect(crossedThreshold(before: 990 * .megabyte, after: 1010 * .megabyte, limit: limit) == .full)
        #expect(crossedThreshold(before: 700 * .megabyte, after: 1100 * .megabyte, limit: limit) == .full)
        #expect(crossedThreshold(before: 810 * .megabyte, after: 820 * .megabyte, limit: limit) == nil)
        #expect(crossedThreshold(before: 0, after: 10, limit: 0) == nil)
    }
}
