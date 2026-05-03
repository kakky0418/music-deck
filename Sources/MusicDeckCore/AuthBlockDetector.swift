import Foundation

public enum AuthBlockDetector {
    private static let markers = [
        "disallowed_useragent",
        "embedded webview",
        "embedded webviews",
        "doesn't comply with google's embedded webview policy",
        "does not comply with google's embedded webview policy",
        "this browser or app may not be secure",
        "sign in with a supported browser"
    ]

    public static func isBlocked(text: String, url: URL?) -> Bool {
        let lowercasedText = text.lowercased()
        if markers.contains(where: { lowercasedText.contains($0) }) {
            return true
        }

        guard let urlString = url?.absoluteString.lowercased() else {
            return false
        }

        return markers.contains(where: { urlString.contains($0) })
    }
}
