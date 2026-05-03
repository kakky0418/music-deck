import Foundation

public struct NowPlayingSnapshot: Codable, Equatable, Sendable {
    public let title: String
    public let artist: String
    public let artworkURL: String

    public init(title: String, artist: String, artworkURL: String) {
        self.title = title
        self.artist = artist
        self.artworkURL = artworkURL
    }

    public var hasDisplayableContent: Bool {
        !title.isEmpty || !artist.isEmpty || !artworkURL.isEmpty
    }
}

public enum NowPlayingExtractionScript {
    public static func javaScript(for service: MusicService) -> String {
        switch service {
        case .youtubeMusic:
            return script(
                titleSelectors: [
                    "ytmusic-player-bar .title",
                    "yt-formatted-string.title",
                    ".content-info-wrapper .title"
                ],
                artistSelectors: [
                    "ytmusic-player-bar .byline",
                    "yt-formatted-string.byline",
                    ".content-info-wrapper .byline"
                ],
                artworkSelectors: [
                    "ytmusic-player-bar img",
                    "ytmusic-player img",
                    "img.image"
                ]
            )
        case .spotify:
            return script(
                titleSelectors: [
                    "[data-testid='context-item-info-title']",
                    "[data-testid='now-playing-widget'] a",
                    "footer a[href*='/track/']"
                ],
                artistSelectors: [
                    "[data-testid='context-item-info-artist']",
                    "[data-testid='now-playing-widget'] span",
                    "footer a[href*='/artist/']"
                ],
                artworkSelectors: [
                    "img[data-testid='cover-art-image']",
                    "[data-testid='cover-art-image'] img",
                    "footer img"
                ]
            )
        }
    }

    private static func script(
        titleSelectors: [String],
        artistSelectors: [String],
        artworkSelectors: [String]
    ) -> String {
        """
        (() => {
          const textFrom = (selectors) => {
            for (const selector of selectors) {
              const element = document.querySelector(selector);
              const text = element?.textContent?.trim();
              if (text) {
                return text;
              }
            }
            return '';
          };
          const imageFrom = (selectors) => {
            for (const selector of selectors) {
              const element = document.querySelector(selector);
              const source = element?.currentSrc || element?.src || element?.getAttribute?.('src') || '';
              if (source) {
                return source;
              }
            }
            return '';
          };
          return JSON.stringify({
            title: textFrom(\(arrayLiteral(titleSelectors))),
            artist: textFrom(\(arrayLiteral(artistSelectors))),
            artworkURL: imageFrom(\(arrayLiteral(artworkSelectors)))
          });
        })();
        """
    }

    private static func arrayLiteral(_ values: [String]) -> String {
        let escapedValues = values.map { value in
            "'\(value.replacingOccurrences(of: "'", with: "\\'"))'"
        }

        return "[\(escapedValues.joined(separator: ", "))]"
    }
}

