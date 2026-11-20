import Testing

@testable import LeashCore

struct AppIdentityTests {
    func snapshot(_ path: String, _ signer: Signer, _ id: String?, outer: BundleSignature? = nil) -> ProcessSnapshot {
        ProcessSnapshot(executablePath: path, signer: signer, signingIdentifier: id, outerBundle: outer)
    }

    @Test func teamSignedToolKeepsItsIdentityAcrossVersionedPaths() {
        let old = snapshot(
            "/Users/me/.local/share/claude/versions/2.1.326", .team("Q6L2SF6YDW"), "com.anthropic.claude-code")
        let new = snapshot(
            "/Users/me/.local/share/claude/versions/2.1.327", .team("Q6L2SF6YDW"), "com.anthropic.claude-code")
        #expect(appKey(for: old) == .signed(team: "Q6L2SF6YDW", identifier: "com.anthropic.claude-code"))
        #expect(appKey(for: old) == appKey(for: new))
    }

    @Test func adHocToolsAreKnownByName() {
        #expect(
            appKey(for: snapshot("/opt/homebrew/Cellar/curl/8.23.0/bin/curl", .adHoc, "curl-5555494")) == .named("curl")
        )
        #expect(appKey(for: snapshot("/opt/homebrew/bin/gh", .adHoc, "a.out")) == .named("gh"))
        #expect(appKey(for: snapshot("/tmp/build/tool", .unsigned, nil)) == .named("tool"))
    }

    @Test func adHocHelpersAreNamedAfterTheirOutermostApp() {
        let path = "/Users/me/Builds/My Tool.app/Contents/Frameworks/My Tool Helper.app/Contents/MacOS/My Tool Helper"
        #expect(appKey(for: snapshot(path, .adHoc, "My Tool Helper")) == .named("My Tool"))
        #expect(
            appKey(for: snapshot("/Applications/Thing.app/Contents/MacOS/thing", .unsigned, nil)) == .named("Thing"))
    }

    @Test func appleCodeUsesTheAppleTeam() {
        #expect(
            appKey(for: snapshot("/usr/sbin/mDNSResponder", .apple, "com.apple.mDNSResponder"))
                == .signed(team: "apple", identifier: "com.apple.mDNSResponder"))
    }

    @Test func helperInsideNestedAppsGroupsUnderOutermostApp() {
        let path =
            "/Applications/Google Chrome.app/Contents/Frameworks/Google Chrome Framework.framework/Helpers/"
            + "Google Chrome Helper.app/Contents/MacOS/Google Chrome Helper"
        #expect(outermostAppBundle(of: path) == "/Applications/Google Chrome.app")
        let chrome = BundleSignature(signer: .team("EQHXZ8M8AV"), identifier: "com.google.Chrome")
        let helper = snapshot(path, .team("EQHXZ8M8AV"), "com.google.Chrome.helper", outer: chrome)
        #expect(appKey(for: helper) == .signed(team: "EQHXZ8M8AV", identifier: "com.google.Chrome"))
    }

    @Test func outerBundleCountsOnlyWhenItsSignerMatches() {
        let dns = BundleSignature(signer: .adHoc, identifier: "com.apple.mDNSResponder")
        let fake = snapshot("/tmp/Evil.app/Contents/MacOS/curl", .apple, "com.apple.curl", outer: dns)
        #expect(appKey(for: fake) == .signed(team: "apple", identifier: "com.apple.curl"))
        let path = "/Applications/Main.app/Contents/Frameworks/Plugin.app/Contents/MacOS/Plugin"
        let main = BundleSignature(signer: .team("MAIN567890"), identifier: "com.main.app")
        let vendor = snapshot(path, .team("VENDOR1234"), "com.vendor.plugin", outer: main)
        #expect(appKey(for: vendor) == .signed(team: "VENDOR1234", identifier: "com.vendor.plugin"))
    }

    @Test func pathsWithoutAnAppBundleHaveNone() {
        #expect(outermostAppBundle(of: "/opt/tools/web.apps/bin/x") == nil)
        #expect(outermostAppBundle(of: "/usr/bin/curl") == nil)
    }

    @Test func simulatorProcessesShareOneKey() {
        let daemon =
            "/Library/Developer/CoreSimulator/Volumes/iOS_23A5/Library/Developer/CoreSimulator/Profiles/"
            + "Runtimes/iOS 27.2.simruntime/Contents/Resources/RuntimeRoot/usr/libexec/mobileassetd"
        let app =
            "/Users/me/Library/Developer/CoreSimulator/Devices/42B78729/data/Containers/Bundle/Application/X/Fixa.app/Fixa"
        #expect(appKey(for: snapshot(daemon, .apple, "com.apple.mobileassetd")) == .simulator)
        #expect(appKey(for: snapshot(app, .adHoc, "fixa")) == .simulator)
    }

    @Test func brewPathsLoseTheirVersion() {
        #expect(displayPath("/opt/homebrew/Cellar/curl/8.23.0/bin/curl") == "brew: curl")
        #expect(displayPath("/usr/local/Cellar/gh/2.80.0/bin/gh") == "brew: gh")
        #expect(displayPath("/opt/homebrew/Cellar/node@22/22.11.0/bin/node") == "brew: node@22")
        #expect(displayPath("/opt/homebrew/opt/curl/bin/curl") == "brew: curl")
        #expect(displayPath("/opt/homebrew/Caskroom/ngrok/3.20.0/ngrok") == "brew: ngrok")
        #expect(displayPath("/usr/bin/curl") == "/usr/bin/curl")
    }

    @Test func appleBasicsAreTheFourServices() {
        #expect(
            AppleBasics.essentials
                == Set(
                    ["com.apple.mDNSResponder", "com.apple.trustd", "com.apple.apsd", "com.apple.timed"]
                        .map { AppKey.signed(team: "apple", identifier: $0) }))
    }
}
