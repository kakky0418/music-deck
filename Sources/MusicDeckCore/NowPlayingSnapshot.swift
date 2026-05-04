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
	                    "ytmusic-player-bar .title"
	                ],
	                artistSelectors: [
	                    "ytmusic-player-bar .byline"
	                ],
                artworkSelectors: [
                    "ytmusic-player-bar img"
                ],
                ignoredTexts: [MusicService.youtubeMusic.title]
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
                ],
                ignoredTexts: [MusicService.spotify.title]
            )
        case .amazonMusic:
            return script(
                titleSelectors: [
                    "[data-testid='player-track-title']",
                    ".player__title"
                ],
                artistSelectors: [
                    "[data-testid='player-track-artist']",
                    ".player__artist"
                ],
                artworkSelectors: [
                    "img[data-testid='music-detail-image']",
                    ".player__image img"
                ],
                fallback: amazonMusicFallbackScript,
                ignoredTexts: [MusicService.amazonMusic.title]
            )
        case .appleMusic:
            return script(
                titleSelectors: [
                    "[data-testid='player-lcd'] [data-testid='track-lockup-title']",
                    ".web-chrome-playback-lcd__song-name",
                    ".web-chrome-playback-lcd__meta a"
                ],
                artistSelectors: [
                    "[data-testid='player-lcd'] [data-testid='track-lockup-subtitle']",
                    ".web-chrome-playback-lcd__sub-copy",
                    ".web-chrome-playback-lcd__meta .song-artist"
                ],
                artworkSelectors: [
                    "[data-testid='player-lcd'] img",
                    ".web-chrome-playback-lcd__artwork img",
                    ".web-chrome-playback-lcd__artwork picture source"
                ],
                fallback: appleMusicFallbackScript,
                ignoredTexts: [
                    MusicService.appleMusic.title,
                    "再生",
                    "停止",
                    "一時停止",
                    "サインイン"
                ]
            )
        }
    }

    private static func script(
        titleSelectors: [String],
        artistSelectors: [String],
        artworkSelectors: [String],
        fallback: String = "null",
        ignoredTexts: [String] = []
    ) -> String {
        """
        (() => {
          try {
          const allElements = (root = document) => {
            const elements = [];
            const visit = (node) => {
              if (!node) {
                return;
              }
              if (node.nodeType === Node.ELEMENT_NODE) {
                elements.push(node);
                if (node.shadowRoot) {
                  visit(node.shadowRoot);
                }
              }
              for (const child of Array.from(node.children || [])) {
                visit(child);
              }
            };
            visit(root);
            return elements;
          };
          const queryAll = (selector, root = document) => allElements(root).filter((element) => {
            try {
              return element.matches?.(selector);
            } catch {
              return false;
            }
          });
          const isVisible = (element) => element && element.getClientRects().length > 0;
          const normalizeText = (value) => (value || '').replace(/\\u00a0/g, ' ').replace(/\\s+/g, ' ').trim();
          const textFrom = (selectors) => {
            for (const selector of selectors) {
              const element = queryAll(selector).find(isVisible);
              const text = normalizeText(element?.textContent);
              if (text) {
                return text;
              }
            }
            return '';
          };
          const imageFrom = (selectors) => {
            for (const selector of selectors) {
              const element = queryAll(selector).find(isVisible);
              const source = element?.currentSrc || element?.src || element?.getAttribute?.('srcset')?.split(' ')?.[0] || element?.getAttribute?.('src') || '';
              if (source) {
                return source;
              }
            }
            return '';
          };
          const ignoredTexts = new Set(\(arrayLiteral(ignoredTexts)).map(normalizeText));
          const hasOnlyIgnoredServiceName = (snapshot) => {
            const title = normalizeText(snapshot?.title);
            const artist = normalizeText(snapshot?.artist);
            return (ignoredTexts.has(title) && (!artist || ignoredTexts.has(artist) || artist === title))
              || (!title && ignoredTexts.has(artist));
          };
          const hasContent = (snapshot) => Boolean(snapshot?.title || snapshot?.artist || snapshot?.artworkURL) && !hasOnlyIgnoredServiceName(snapshot);
          const fallbackSnapshot = (\(fallback));
          if (hasContent(fallbackSnapshot)) {
            return JSON.stringify(fallbackSnapshot);
          }
          const snapshot = {
            title: textFrom(\(arrayLiteral(titleSelectors))),
            artist: textFrom(\(arrayLiteral(artistSelectors))),
            artworkURL: imageFrom(\(arrayLiteral(artworkSelectors)))
          };
          return JSON.stringify(hasContent(snapshot) ? snapshot : { title: '', artist: '', artworkURL: '' });
          } catch {
            return JSON.stringify({ title: '', artist: '', artworkURL: '' });
          }
        })();
        """
    }

    private static let amazonMusicFallbackScript = """
    (() => {
      const progress = queryAll("[aria-label='Playback Progress']").find(isVisible);
      const parentOf = (element) => element?.parentElement || element?.getRootNode?.().host || null;
      const text = (root, selectors) => {
        for (const selector of selectors) {
          const element = queryAll(selector, root).find(isVisible);
          const value = element?.textContent?.trim()
            || element?.getAttribute?.('title')?.trim()
            || element?.getAttribute?.('secondary-text')?.trim()
            || '';
          if (value) {
            return value;
          }
        }
        return '';
      };
      const titleSelectors = ['[data-testid="player-track-title"]', 'a[href*="/albums/"]', '.col1 music-link', '.col1 a', 'music-link[title]', 'music-link:nth-of-type(1)', 'a:nth-of-type(1)'];
      const artistSelectors = ['[data-testid="player-track-artist"]', 'a[href*="/artists/"]', '.col2 music-link', '.col2 a', 'music-link[secondary-text]', 'music-link:nth-of-type(2)', 'a:nth-of-type(2)'];
      const ignoredTexts = new Set(['-', 'Context Menu', '前に戻る', '再生', '停止', '次に進む', 'Volume', 'maximize']);
      const textCandidates = (root, title) => queryAll('*', root)
        .filter(isVisible)
        .map((element) => element.textContent?.trim() || '')
        .filter((value) => value && value.length < 80 && !value.includes('\\n'))
        .filter((value) => value !== title && !ignoredTexts.has(value))
        .filter((value) => !value.match(/\\d{1,2}:\\d{2}/))
        .filter((value) => !['前に戻る', '次に進む', 'シャッフル'].some((ignored) => value.includes(ignored)));
      const hasPlayerText = (root) => {
        const title = text(root, titleSelectors);
        const artist = text(root, artistSelectors);
        return Boolean(title && (artist || textCandidates(root, title)[0]));
      };
      const findPlayerRoot = () => {
        let candidate = progress;
        for (let index = 0; candidate && index < 12; index += 1) {
          if (hasPlayerText(candidate)) {
            return candidate;
          }
          candidate = parentOf(candidate);
        }
        return parentOf(progress);
      };
      const root = findPlayerRoot();
      const image = queryAll('music-image, img', root).find(isVisible);
      const artworkURL = image?.currentSrc || image?.src || image?.getAttribute?.('src') || '';
      const title = text(root, titleSelectors);
      let artist = text(root, artistSelectors);
      if (!artist || artist === title) {
        artist = textCandidates(root, title)[0] || artist;
      }
      return {
        title,
        artist,
        artworkURL
      };
    })()
    """

    private static let appleMusicFallbackScript = """
    (() => {
      const lcd = document.querySelector("[data-testid='player-lcd']");
      const text = (selectors) => {
        for (const selector of selectors) {
          const element = lcd?.querySelector(selector);
          const value = element?.textContent?.trim();
          if (value) {
            return value;
          }
        }
        return '';
      };
      const image = lcd?.querySelector("img");
      const artworkURL = image?.currentSrc || image?.src || image?.getAttribute?.('srcset')?.split(' ')?.[0] || image?.getAttribute?.('src') || '';
      return {
        title: text(["[data-testid='track-lockup-title']", '.track-lockup__title', 'a']),
        artist: text(["[data-testid='track-lockup-subtitle']", '.track-lockup__subtitle', 'span']),
        artworkURL
      };
    })()
    """

    private static func arrayLiteral(_ values: [String]) -> String {
        let escapedValues = values.map { value in
            "'\(value.replacingOccurrences(of: "'", with: "\\'"))'"
        }

        return "[\(escapedValues.joined(separator: ", "))]"
    }
}
