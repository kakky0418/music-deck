import Foundation
import Testing
@testable import MusicDeckCore

@Suite("ナビゲーション方針")
struct NavigationPolicyTests {
    @Test("YouTube Music はアプリ内で許可する")
    func allowsYouTubeMusic() throws {
        let url = try #require(URL(string: "https://music.youtube.com/watch?v=abc"))

        #expect(NavigationPolicy.decision(for: url) == .allowInApp)
    }

    @Test("Google ログインはアプリ内検証のため許可する")
    func allowsGoogleLogin() throws {
        let url = try #require(URL(string: "https://accounts.google.com/signin/v2/identifier"))

        #expect(NavigationPolicy.decision(for: url) == .allowInApp)
    }

    @Test("YouTube アカウントの SID 設定はアプリ内で許可する")
    func allowsYouTubeAccountSetSID() throws {
        let url = try #require(URL(string: "https://accounts.youtube.com/accounts/SetSID"))

        #expect(NavigationPolicy.decision(for: url) == .allowInApp)
    }

    @Test("外部リンクは既定ブラウザで開く")
    func opensExternalLinksExternally() throws {
        let url = try #require(URL(string: "https://example.com/"))

        #expect(NavigationPolicy.decision(for: url) == .openExternally)
    }

    @Test("about blank は WebKit 内部遷移として許可する")
    func allowsAboutBlank() throws {
        let url = try #require(URL(string: "about:blank"))

        #expect(NavigationPolicy.decision(for: url) == .allowInApp)
    }

    @Test("サブフレームの外部 URL は外部アプリで開かない")
    func allowsExternalSubframeNavigation() throws {
        let url = try #require(URL(string: "https://example.com/tracker"))

        #expect(NavigationPolicy.decision(for: url, isMainFrame: false) == .allowInApp)
    }

    @Test("ブラウザで開く URL が about blank ならホームに戻す")
    func browserOpenURLFallsBackForAboutBlank() throws {
        let currentURL = try #require(URL(string: "about:blank"))
        let homeURL = try #require(URL(string: "https://music.youtube.com/"))

        #expect(NavigationPolicy.browserOpenURL(currentURL: currentURL, fallbackURL: homeURL) == homeURL)
    }

    @Test("ブラウザで開く URL が通常ページならその URL を使う")
    func browserOpenURLUsesCurrentPage() throws {
        let currentURL = try #require(URL(string: "https://music.youtube.com/watch?v=abc"))
        let homeURL = try #require(URL(string: "https://music.youtube.com/"))

        #expect(NavigationPolicy.browserOpenURL(currentURL: currentURL, fallbackURL: homeURL) == currentURL)
    }
}
