import Foundation
import Testing
@testable import MusicDeckCore

@Suite("認証ブロック検出")
struct AuthBlockDetectorTests {
    @Test("disallowed_useragent を検出する")
    func detectsDisallowedUserAgent() throws {
        let url = try #require(URL(string: "https://accounts.google.com/o/oauth2/v2/auth"))

        #expect(AuthBlockDetector.isBlocked(text: "Error 403: disallowed_useragent", url: url))
    }

    @Test("通常の YouTube Music ページはブロック扱いしない")
    func doesNotDetectNormalPage() throws {
        let url = try #require(URL(string: "https://music.youtube.com/"))

        #expect(!AuthBlockDetector.isBlocked(text: "YouTube Music", url: url))
    }
}
