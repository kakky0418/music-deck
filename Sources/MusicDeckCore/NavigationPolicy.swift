import Foundation

public enum NavigationDecision: Equatable {
    case allowInApp
    case openExternally
}

public enum NavigationPolicy {
    private static let inAppHosts: Set<String> = MusicService.allCases.reduce(into: Set<String>()) { hosts, service in
        hosts.formUnion(service.allowedHosts)
    }

    public static func decision(for url: URL, isMainFrame: Bool = true) -> NavigationDecision {
        if !isMainFrame {
            return .allowInApp
        }

        guard let scheme = url.scheme?.lowercased() else {
            return .openExternally
        }

        if scheme == "about", url.absoluteString.lowercased() == "about:blank" {
            return .allowInApp
        }

        guard scheme == "https" || scheme == "http" else {
            return .openExternally
        }

        guard let host = url.host(percentEncoded: false)?.lowercased() else {
            return .openExternally
        }

        if inAppHosts.contains(host) || host.hasSuffix(".googleusercontent.com") {
            return .allowInApp
        }

        return .openExternally
    }

    public static func browserOpenURL(currentURL: URL?, fallbackURL: URL) -> URL {
        guard let currentURL else {
            return fallbackURL
        }

        if currentURL.scheme?.lowercased() == "about" {
            return fallbackURL
        }

        return currentURL
    }
}
