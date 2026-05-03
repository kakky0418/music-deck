import Testing
@testable import MusicDeckCore

@Suite("ユーザーエージェント方針")
struct UserAgentPolicyTests {
    @Test("Safari 互換トークンを生成する")
    func safariCompatibleApplicationName() {
        let applicationName = UserAgentPolicy.safariCompatibleApplicationName(safariVersion: "26.2")

        #expect(applicationName == "Version/26.2 Safari/605.1.15")
    }

    @Test("Safari バージョンが空なら fallback を使う")
    func safariCompatibleApplicationNameFallsBack() {
        let applicationName = UserAgentPolicy.safariCompatibleApplicationName(safariVersion: "")

        #expect(applicationName == "Version/18.0 Safari/605.1.15")
    }
}
