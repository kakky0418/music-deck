import Foundation
import Testing
@testable import MusicDeckCore

@Suite("音楽サービス")
struct MusicServiceTests {
    @Test("初期サービスは YouTube Music、Spotify、Amazon Music、Apple Music")
    func initialServices() {
        #expect(MusicService.allCases == [.youtubeMusic, .spotify, .amazonMusic, .appleMusic])
    }

    @Test("YouTube Music のホーム URL")
    func youtubeMusicHomeURL() {
        #expect(MusicService.youtubeMusic.homeURL.absoluteString == "https://music.youtube.com/")
    }

    @Test("Spotify のホーム URL")
    func spotifyHomeURL() {
        #expect(MusicService.spotify.homeURL.absoluteString == "https://open.spotify.com/")
    }

    @Test("Amazon Music のホーム URL")
    func amazonMusicHomeURL() {
        #expect(MusicService.amazonMusic.homeURL.absoluteString == "https://music.amazon.co.jp/")
    }

    @Test("Apple Music のホーム URL")
    func appleMusicHomeURL() {
        #expect(MusicService.appleMusic.homeURL.absoluteString == "https://music.apple.com/jp/browse")
    }

    @Test("Spotify の再生ボタン selector を持つ")
    func spotifyPlayPauseScript() {
        let script = MusicService.spotify.javaScript(for: .togglePlayPause)

        #expect(script.contains("control-button-playpause"))
        #expect(script.contains("button.click()"))
    }

    @Test("Amazon Music の再生ボタン selector を持つ")
    func amazonMusicPlayPauseScript() {
        let script = MusicService.amazonMusic.javaScript(for: .togglePlayPause)

        #expect(script.contains("button[aria-label=\\'再生\\']"))
        #expect(script.contains("button[aria-label=\\'一時停止\\']"))
        #expect(script.contains("getClientRects().length"))
        #expect(script.contains("return false;"))
        #expect(!script.contains("throw new Error"))
        #expect(script.contains("button.click()"))
    }

    @Test("Apple Music の再生ボタン selector を持つ")
    func appleMusicPlayPauseScript() {
        let script = MusicService.appleMusic.javaScript(for: .togglePlayPause)

        #expect(script.contains(".playback-play__play"))
        #expect(script.contains(".playback-play__pause"))
        #expect(script.contains("getClientRects().length"))
        #expect(script.contains("button.click()"))
    }

    @Test("Amazon Music の次へ戻る selector は実 player の aria-label を持つ")
    func amazonMusicTransportScripts() {
        let nextScript = MusicService.amazonMusic.javaScript(for: .nextTrack)
        let previousScript = MusicService.amazonMusic.javaScript(for: .previousTrack)

        #expect(nextScript.contains("button[aria-label=\\'次に進む\\']"))
        #expect(previousScript.contains("button[aria-label=\\'前に戻る\\']"))
    }

    @Test("Apple Music の次へ戻る selector は実 player の class を持つ")
    func appleMusicTransportScripts() {
        let nextScript = MusicService.appleMusic.javaScript(for: .nextTrack)
        let previousScript = MusicService.appleMusic.javaScript(for: .previousTrack)

        #expect(nextScript.contains(".playback-controls__next"))
        #expect(previousScript.contains(".playback-controls__previous"))
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

    @Test("Amazon Music のログイン host を許可する")
    func amazonMusicLoginHosts() throws {
        let url = try #require(URL(string: "https://www.amazon.co.jp/ap/signin"))

        #expect(NavigationPolicy.decision(for: url) == .allowInApp)
    }

    @Test("Amazon Music Web Player を許可する")
    func amazonMusicPlayerHost() throws {
        let url = try #require(URL(string: "https://music.amazon.co.jp/albums/abc"))

        #expect(NavigationPolicy.decision(for: url) == .allowInApp)
    }

    @Test("Apple Music のログイン host を許可する")
    func appleMusicLoginHosts() throws {
        let url = try #require(URL(string: "https://idmsa.apple.com/appleauth/auth/signin"))

        #expect(NavigationPolicy.decision(for: url) == .allowInApp)
    }

    @Test("Apple Music Web Player を許可する")
    func appleMusicPlayerHost() throws {
        let url = try #require(URL(string: "https://music.apple.com/jp/album/example/123"))

        #expect(NavigationPolicy.decision(for: url) == .allowInApp)
    }

    @Test("サービスごとの fallback theme を持つ")
    func serviceThemePreset() {
        #expect(MusicService.youtubeMusic.themePreset.accentHex == "#ff0033")
        #expect(MusicService.spotify.themePreset.accentHex == "#1ed760")
        #expect(MusicService.amazonMusic.themePreset.accentHex == "#00a8e1")
        #expect(MusicService.appleMusic.themePreset.accentHex == "#fa2d48")
    }

    @Test("YouTube Music の再生中情報抽出 script は artwork を拾う")
    func youtubeMusicNowPlayingScript() {
        let script = NowPlayingExtractionScript.javaScript(for: .youtubeMusic)

        #expect(script.contains("ytmusic-player-bar img"))
        #expect(script.contains("hasOnlyIgnoredServiceName"))
        #expect(script.contains("'YouTube Music'"))
        #expect(!script.contains("yt-formatted-string.title"))
        #expect(!script.contains(".content-info-wrapper .title"))
        #expect(script.contains("JSON.stringify"))
    }

    @Test("Spotify の再生中情報抽出 script は cover art を拾う")
    func spotifyNowPlayingScript() {
        let script = NowPlayingExtractionScript.javaScript(for: .spotify)

        #expect(script.contains("cover-art-image"))
        #expect(script.contains("JSON.stringify"))
    }

    @Test("Amazon Music の再生中情報抽出 script は artwork を拾う")
    func amazonMusicNowPlayingScript() {
        let script = NowPlayingExtractionScript.javaScript(for: .amazonMusic)

        #expect(script.contains("Playback Progress"))
        #expect(script.contains("findPlayerRoot"))
        #expect(script.contains("shadowRoot"))
        #expect(script.contains("allElements"))
        #expect(script.contains("textCandidates"))
        #expect(script.contains("artist === title"))
        #expect(script.contains("hasPlayerText"))
        #expect(script.contains("value.match"))
        #expect(script.contains("music-image"))
        #expect(!script.contains("music-image-row"))
        #expect(script.contains("JSON.stringify"))
    }

    @Test("Apple Music の再生中情報抽出 script は artwork を拾う")
    func appleMusicNowPlayingScript() {
        let script = NowPlayingExtractionScript.javaScript(for: .appleMusic)

        #expect(script.contains("fallbackSnapshot"))
        #expect(script.contains("player-lcd"))
        #expect(script.contains("track-lockup-title"))
        #expect(script.contains("'再生'"))
        #expect(script.contains("'サインイン'"))
        #expect(script.contains("\\u00a0"))
        #expect(script.contains("ignoredTexts.has(artist)"))
        #expect(script.contains("!title && ignoredTexts.has(artist)"))
        #expect(!script.contains("[data-testid='song-title']"))
        #expect(!script.contains("[data-testid='song-artist']"))
        #expect(!script.contains("[data-testid='artwork-component'] img"))
        #expect(script.contains("JSON.stringify"))
    }

    @Test("再生中情報抽出 script は fallback を通常 selector より優先する")
    func nowPlayingScriptPrefersFallbackSnapshot() {
        let script = NowPlayingExtractionScript.javaScript(for: .amazonMusic)

        #expect(script.contains("if (hasContent(fallbackSnapshot))"))
        #expect(script.contains("return JSON.stringify(fallbackSnapshot);"))
    }
}
