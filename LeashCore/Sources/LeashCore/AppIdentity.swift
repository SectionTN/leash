/// Who signed a process's code.
public enum Signer: Hashable, Codable, Sendable {
    case apple
    case team(String)
    case adHoc, unsigned
}

/// A bundle's signing identifier and who signed it, read from a valid code signature.
public struct BundleSignature: Hashable, Sendable {
    public let signer: Signer
    public let identifier: String

    public init(signer: Signer, identifier: String) {
        self.signer = signer
        self.identifier = identifier
    }
}

/// What the extension learns about the process behind a flow, from its audit token and code signature.
public struct ProcessSnapshot: Hashable, Sendable {
    public let executablePath: String
    public let signer: Signer
    public let signingIdentifier: String?
    /// The outermost app the executable lives in, nil when it has no valid signature.
    public let outerBundle: BundleSignature?

    public init(executablePath: String, signer: Signer, signingIdentifier: String?, outerBundle: BundleSignature?) {
        self.executablePath = executablePath
        self.signer = signer
        self.signingIdentifier = signingIdentifier
        self.outerBundle = outerBundle
    }
}

/// The identity rules and usage attach to. Apple code uses the team `"apple"`.
public enum AppKey: Hashable, Codable, Sendable {
    case signed(team: String, identifier: String)
    case named(String)
    case simulator
}

public func appKey(for process: ProcessSnapshot) -> AppKey {
    let path = process.executablePath
    if path.contains("/Library/Developer/CoreSimulator/") || path.contains(".simruntime/") {
        return .simulator
    }
    let outer = process.outerBundle.flatMap { $0.signer == process.signer ? $0.identifier : nil }
    let identifier = outer ?? process.signingIdentifier
    switch (process.signer, identifier) {
    case (.apple, let identifier?):
        return .signed(team: "apple", identifier: identifier)
    case (.team(let team), let identifier?):
        return .signed(team: team, identifier: identifier)
    default:
        if let bundle = outermostAppBundle(of: path) {
            return .named(String(lastComponent(of: bundle).dropLast(".app".count)))
        }
        return .named(lastComponent(of: path))
    }
}

/// The path up to the first component that ends in `.app`, or nil when there is none.
public func outermostAppBundle(of path: String) -> String? {
    var components: [Substring] = []
    for component in path.split(separator: "/", omittingEmptySubsequences: false) {
        components.append(component)
        if component.count > ".app".count && component.hasSuffix(".app") {
            return components.joined(separator: "/")
        }
    }
    return nil
}

/// The path with Homebrew's version folders removed: `/opt/homebrew/Cellar/curl/8.23.0/bin/curl` becomes `brew: curl`.
public func displayPath(_ path: String) -> String {
    for prefix in ["/opt/homebrew/", "/usr/local/"] where path.hasPrefix(prefix) {
        let parts = path.dropFirst(prefix.count).split(separator: "/", omittingEmptySubsequences: false)
        if parts.count >= 3, parts[0] == "Cellar" || parts[0] == "opt", !parts[1].isEmpty {
            return "brew: \(parts[1])"
        }
    }
    return path
}

public enum AppleBasics {
    /// DNS, certificate checks, push and time.
    public static let essentials: Set<AppKey> = Set(
        ["com.apple.mDNSResponder", "com.apple.trustd", "com.apple.apsd", "com.apple.timed"]
            .map { AppKey.signed(team: "apple", identifier: $0) }
    )
}

private func lastComponent(of path: String) -> String {
    path.split(separator: "/").last.map(String.init) ?? path
}
