public enum AppState: String, Codable, Sendable {
    case allowed, essential, blocked
}

public enum DropReason: Equatable, Sendable {
    case unknown, blocked, appLimit, allowance
}

/// `pass` leaves a flow alone. `watch` counts it window by window.
public enum Verdict: Equatable, Sendable {
    case pass, watch
    case drop(DropReason)
}

/// Today's usage on the plan, with top-ups already added to the limits.
public struct UsageContext: Equatable, Sendable {
    public var todayBytes: Bytes
    public var todayLimit: Bytes
    public var appTodayBytes: Bytes
    /// Nil when the app has no limit of its own.
    public var appLimit: Bytes?

    public init(todayBytes: Bytes, todayLimit: Bytes, appTodayBytes: Bytes, appLimit: Bytes?) {
        self.todayBytes = todayBytes
        self.todayLimit = todayLimit
        self.appTodayBytes = appTodayBytes
        self.appLimit = appLimit
    }
}

/// Decides a flow. A nil state is an app Leash has not seen before.
public func decide(state: AppState?, onPlan: Bool, usage: UsageContext) -> Verdict {
    guard onPlan else { return .pass }
    guard let state else { return .drop(.unknown) }
    if state == .blocked { return .drop(.blocked) }
    if let limit = usage.appLimit, usage.appTodayBytes >= limit { return .drop(.appLimit) }
    if state != .essential && usage.todayBytes >= usage.todayLimit { return .drop(.allowance) }
    return .watch
}
