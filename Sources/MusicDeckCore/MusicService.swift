import Foundation

public enum MusicService: String, CaseIterable, Equatable, Identifiable, Sendable {
    case youtubeMusic
    case spotify
    case amazonMusic
    case appleMusic

    public var id: String {
        rawValue
    }

    public var title: String {
        switch self {
        case .youtubeMusic:
            return "YouTube Music"
        case .spotify:
            return "Spotify"
        case .amazonMusic:
            return "Amazon Music"
        case .appleMusic:
            return "Apple Music"
        }
    }

    public var shortTitle: String {
        switch self {
        case .youtubeMusic:
            return "YT"
        case .spotify:
            return "SP"
        case .amazonMusic:
            return "AM"
        case .appleMusic:
            return "AP"
        }
    }

    public var symbolName: String {
        switch self {
        case .youtubeMusic:
            return "play.circle.fill"
        case .spotify:
            return "music.note.list"
        case .amazonMusic:
            return "music.quarternote.3"
        case .appleMusic:
            return "music.note"
        }
    }

    public var themePreset: ServiceThemePreset {
        switch self {
        case .youtubeMusic:
            return ServiceThemePreset(
                accentHex: "#ff0033",
                secondaryAccentHex: "#ff5f3d",
                backgroundHex: "#18070b"
            )
        case .spotify:
            return ServiceThemePreset(
                accentHex: "#1ed760",
                secondaryAccentHex: "#a7e22e",
                backgroundHex: "#07150d"
            )
        case .amazonMusic:
            return ServiceThemePreset(
                accentHex: "#00a8e1",
                secondaryAccentHex: "#25d5ff",
                backgroundHex: "#06131c"
            )
        case .appleMusic:
            return ServiceThemePreset(
                accentHex: "#fa2d48",
                secondaryAccentHex: "#fb5c74",
                backgroundHex: "#1c070d"
            )
        }
    }

    public var homeURL: URL {
        switch self {
        case .youtubeMusic:
            return URL(string: "https://music.youtube.com/")!
        case .spotify:
            return URL(string: "https://open.spotify.com/")!
        case .amazonMusic:
            return URL(string: "https://music.amazon.co.jp/")!
        case .appleMusic:
            return URL(string: "https://music.apple.com/jp/browse")!
        }
    }

    public var allowedHosts: Set<String> {
        switch self {
        case .youtubeMusic:
            return [
                "music.youtube.com",
                "www.youtube.com",
                "youtube.com",
                "accounts.youtube.com",
                "accounts.google.com",
                "myaccount.google.com",
                "ssl.gstatic.com",
                "fonts.gstatic.com",
                "fonts.googleapis.com",
                "www.gstatic.com"
            ]
        case .spotify:
            return [
                "open.spotify.com",
                "accounts.spotify.com",
                "login5.spotify.com",
                "spclient.wg.spotify.com",
                "gew-spclient.spotify.com",
                "api-partner.spotify.com",
                "api.spotify.com",
                "xpui.app.spotify.com",
                "encore.scdn.co",
                "i.scdn.co",
                "seeded-session-images.scdn.co",
                "lineup-images.scdn.co"
            ]
        case .amazonMusic:
            return [
                "music.amazon.co.jp",
                "music.amazon.com",
                "www.amazon.co.jp",
                "www.amazon.com",
                "amazon.co.jp",
                "amazon.com",
                "images-na.ssl-images-amazon.com",
                "m.media-amazon.com",
                "a.media-amazon.com",
                "d1.awsstatic.com",
                "fls-fe.amazon.co.jp",
                "fls-na.amazon.com"
            ]
        case .appleMusic:
            return [
                "music.apple.com",
                "beta.music.apple.com",
                "idmsa.apple.com",
                "appleid.apple.com",
                "auth.apple.com",
                "is1-ssl.mzstatic.com",
                "is2-ssl.mzstatic.com",
                "is3-ssl.mzstatic.com",
                "is4-ssl.mzstatic.com",
                "is5-ssl.mzstatic.com",
                "amp-api.music.apple.com",
                "play.itunes.apple.com"
            ]
        }
    }

    public func javaScript(for command: PlayerCommand) -> String {
        switch self {
        case .youtubeMusic:
            return youtubeMusicJavaScript(for: command)
        case .spotify:
            return spotifyJavaScript(for: command)
        case .amazonMusic:
            return amazonMusicJavaScript(for: command)
        case .appleMusic:
            return appleMusicJavaScript(for: command)
        }
    }

    private func youtubeMusicJavaScript(for command: PlayerCommand) -> String {
        switch command {
        case .togglePlayPause:
            return Self.clickScript(
                selectors: [
                    "ytmusic-player-bar .play-pause-button",
                    "ytmusic-player-bar tp-yt-paper-icon-button.play-pause-button",
                    "button[aria-label='Play']",
                    "button[aria-label='Pause']"
                ],
	                errorCode: "play_pause_button_not_found"
            )
        case .nextTrack:
            return Self.clickScript(
                selectors: [
                    "ytmusic-player-bar .next-button",
                    "ytmusic-player-bar tp-yt-paper-icon-button.next-button",
                    "button[aria-label='Next']"
                ],
	                errorCode: "next_button_not_found"
            )
        case .previousTrack:
            return Self.clickScript(
                selectors: [
                    "ytmusic-player-bar .previous-button",
                    "ytmusic-player-bar tp-yt-paper-icon-button.previous-button",
                    "button[aria-label='Previous']"
                ],
	                errorCode: "previous_button_not_found"
            )
        }
    }

    private func spotifyJavaScript(for command: PlayerCommand) -> String {
        switch command {
        case .togglePlayPause:
            return Self.clickScript(
                selectors: [
                    "[data-testid='control-button-playpause']",
                    "button[aria-label='再生']",
                    "button[aria-label='一時停止']",
                    "button[aria-label='Play']",
                    "button[aria-label='Pause']"
                ],
                errorCode: "spotify_play_pause_button_not_found"
            )
        case .nextTrack:
            return Self.clickScript(
                selectors: [
                    "[data-testid='control-button-skip-forward']",
                    "button[aria-label='次へ']",
                    "button[aria-label='Next']"
                ],
                errorCode: "spotify_next_button_not_found"
            )
        case .previousTrack:
            return Self.clickScript(
                selectors: [
                    "[data-testid='control-button-skip-back']",
                    "button[aria-label='前へ']",
                    "button[aria-label='Previous']"
                ],
                errorCode: "spotify_previous_button_not_found"
            )
        }
    }

    private func amazonMusicJavaScript(for command: PlayerCommand) -> String {
        switch command {
        case .togglePlayPause:
            return Self.clickScript(
                selectors: [
                    "music-button[player-play-button]",
                    "music-button[player-pause-button]",
                    "button[aria-label='再生']",
                    "button[aria-label='一時停止']",
                    "button[aria-label='Play']",
                    "button[aria-label='Pause']"
                ],
                errorCode: "amazon_music_play_pause_button_not_found"
            )
        case .nextTrack:
            return Self.clickScript(
                selectors: [
                    "music-button[player-next-button]",
                    "button[aria-label='次に進む']",
                    "button[aria-label='次へ']",
                    "button[aria-label='Next']"
                ],
                errorCode: "amazon_music_next_button_not_found"
            )
        case .previousTrack:
            return Self.clickScript(
                selectors: [
                    "music-button[player-previous-button]",
                    "button[aria-label='前に戻る']",
                    "button[aria-label='前へ']",
                    "button[aria-label='Previous']"
                ],
                errorCode: "amazon_music_previous_button_not_found"
            )
        }
    }

    private func appleMusicJavaScript(for command: PlayerCommand) -> String {
        switch command {
        case .togglePlayPause:
            return Self.clickScript(
                selectors: [
                    ".playback-play__play",
                    ".playback-play__pause",
                    "button[aria-label='再生']",
                    "button[aria-label='一時停止']",
                    "button[aria-label='Play']",
                    "button[aria-label='Pause']",
                    ".web-chrome-playback-controls__playback-btn"
                ],
                errorCode: "apple_music_play_pause_button_not_found"
            )
        case .nextTrack:
            return Self.clickScript(
                selectors: [
                    ".playback-controls__next",
                    "button[aria-label='次へ']",
                    "button[aria-label='Next']",
                    ".web-chrome-playback-controls__next-btn"
                ],
                errorCode: "apple_music_next_button_not_found"
            )
        case .previousTrack:
            return Self.clickScript(
                selectors: [
                    ".playback-controls__previous",
                    "button[aria-label='前へ']",
                    "button[aria-label='Previous']",
                    ".web-chrome-playback-controls__previous-btn"
                ],
                errorCode: "apple_music_previous_button_not_found"
            )
        }
    }

    private static func clickScript(selectors: [String], errorCode _: String) -> String {
        let selectorList = selectors
            .map { "'\($0.replacingOccurrences(of: "'", with: "\\'"))'" }
            .joined(separator: ", ")

        return """
        (() => {
          const selectors = [\(selectorList)];
          const isVisible = (element) => {
            const style = window.getComputedStyle(element);
            return element.getClientRects().length > 0 &&
              style.visibility !== 'hidden' &&
              style.display !== 'none';
          };
          const button = selectors
            .map((selector) => document.querySelector(selector))
            .find((element) => element && !element.disabled && element.getAttribute('aria-disabled') !== 'true' && isVisible(element));
          if (!button) {
            return false;
          }
          button.click();
          return true;
        })();
        """
    }
}
