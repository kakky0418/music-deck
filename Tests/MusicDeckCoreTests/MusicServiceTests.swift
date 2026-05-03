import Foundation
import Testing
@testable import MusicDeckCore

@Suite("音楽サービス")
struct MusicServiceTests {
    @Test("初期サービスは YouTube Music と Spotify")
    func initialServices() {
        #expect(MusicService.allCases == [.youtubeMusic, .spotify])
    }

    @Test("YouTube Music のホーム URL")
    func youtubeMusicHomeURL() {
        #expect(MusicService.youtubeMusic.homeURL.absoluteString == "https://music.youtube.com/")
    }

    @Test("Spotify のホーム URL")
    func spotifyHomeURL() {
        #expect(MusicService.spotify.homeURL.absoluteString == "https://open.spotify.com/")
    }

    @Test("Spotify の再生ボタン selector を持つ")
    func spotifyPlayPauseScript() {
        let script = MusicService.spotify.javaScript(for: .togglePlayPause)

        #expect(script.contains("control-button-playpause"))
        #expect(script.contains("button.click()"))
    }

    @Test("Spotify のログイン host を許可する")
    func spotifyLoginHosts() throws {
        let url = try #require(URL(string: "https://accounts.spotify.com/login"))

        #expect(NavigationPolicy.decision(for: url) == .allowInApp)
    }

    @Test("Spotify Web Player を許可する")
    func spotifyPlayerHost() throws {
        let url = try #require(URL(string: "https://open.spotify.com/playlist/abc"))

        #expect(NavigationPolicy.decision(for: url) == .allowInApp)
    }

    @Test("サービスごとの fallback theme を持つ")
    func serviceThemePreset() {
        #expect(MusicService.youtubeMusic.themePreset.accentHex == "#ff0033")
        #expect(MusicService.spotify.themePreset.accentHex == "#1ed760")
    }

    @Test("YouTube Music の再生中情報抽出 script は artwork を拾う")
    func youtubeMusicNowPlayingScript() {
        let script = NowPlayingExtractionScript.javaScript(for: .youtubeMusic)

        #expect(script.contains("ytmusic-player-bar img"))
        #expect(script.contains("JSON.stringify"))
    }

    @Test("Spotify の再生中情報抽出 script は cover art を拾う")
    func spotifyNowPlayingScript() {
        let script = NowPlayingExtractionScript.javaScript(for: .spotify)

        #expect(script.contains("cover-art-image"))
        #expect(script.contains("JSON.stringify"))
    }
}
