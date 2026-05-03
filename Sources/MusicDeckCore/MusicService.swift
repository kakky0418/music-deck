import Foundation

public enum MusicService: String, CaseIterable, Equatable, Identifiable, Sendable {
    case youtubeMusic
    case spotify

    public var id: String {
        rawValue
    }

    public var title: String {
        switch self {
        case .youtubeMusic:
            return "YouTube Music"
        case .spotify:
            return "Spotify"
        }
    }

    public var shortTitle: String {
        switch self {
        case .youtubeMusic:
            return "YT"
        case .spotify:
            return "SP"
        }
    }

    public var symbolName: String {
        switch self {
        case .youtubeMusic:
            return "play.circle.fill"
        case .spotify:
            return "music.note.list"
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
        }
    }

    public var homeURL: URL {
        switch self {
        case .youtubeMusic:
            return URL(string: "https://music.youtube.com/")!
        case .spotify:
            return URL(string: "https://open.spotify.com/")!
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
        }
    }

    public func javaScript(for command: PlayerCommand) -> String {
        switch self {
        case .youtubeMusic:
            return youtubeMusicJavaScript(for: command)
        case .spotify:
            return spotifyJavaScript(for: command)
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

    private static func clickScript(selectors: [String], errorCode: String) -> String {
        let selectorList = selectors
            .map { "'\($0.replacingOccurrences(of: "'", with: "\\'"))'" }
            .joined(separator: ", ")

        return """
        (() => {
          const selectors = [\(selectorList)];
          const button = selectors
            .map((selector) => document.querySelector(selector))
            .find((element) => element && !element.disabled);
          if (!button) {
            throw new Error('\(errorCode)');
          }
          button.click();
          return true;
        })();
        """
    }
}
