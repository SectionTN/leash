import Foundation

/// Batches blocked apps into one summary per interval and names each app once. The first block goes out at once.
public struct BlockedDigest: Equatable, Sendable {
    public let interval: TimeInterval
    private var pending: Set<AppKey> = []
    private var announced: Set<AppKey> = []
    private var lastDelivery: Date?
    /// When each blocked app last tried to connect, for the menu.
    public private(set) var lastAttempts: [AppKey: Date] = [:]

    public init(interval: TimeInterval = 600) {
        self.interval = interval
    }

    public mutating func noteBlocked(_ app: AppKey, at date: Date) {
        lastAttempts[app] = date
        if !announced.contains(app) { pending.insert(app) }
    }

    /// Lets an app be announced again, for example after the user changes its state.
    public mutating func forget(_ app: AppKey) {
        announced.remove(app)
        pending.remove(app)
        lastAttempts[app] = nil
    }

    /// The apps blocked since the last digest, or nil when there are none or the interval hasn't passed.
    public mutating func takeDigest(at date: Date) -> Set<AppKey>? {
        guard !pending.isEmpty else { return nil }
        if let lastDelivery {
            // A clock set back gives a negative gap, which counts as the interval having passed.
            let elapsed = date.timeIntervalSince(lastDelivery)
            if elapsed >= 0 && elapsed < interval { return nil }
        }
        defer {
            announced.formUnion(pending)
            pending = []
            lastDelivery = date
        }
        return pending
    }
}

public enum AllowanceThreshold: Int, Sendable {
    case eightyPercent = 80
    case full = 100
}

/// The highest threshold that going from `before` to `after` crossed, or nil.
public func crossedThreshold(before: Bytes, after: Bytes, limit: Bytes) -> AllowanceThreshold? {
    guard limit > 0 else { return nil }
    return [AllowanceThreshold.full, .eightyPercent].first { threshold in
        let percent = Bytes(threshold.rawValue)
        // Split so that a huge limit can't overflow.
        let mark = limit / 100 * percent + limit % 100 * percent / 100
        return before < mark && after >= mark
    }
}
