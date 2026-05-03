import Foundation

public enum UserAgentPolicy {
    public static let fallbackSafariVersion = "18.0"

    public static func safariCompatibleApplicationName(safariVersion: String?) -> String {
        let normalizedVersion = safariVersion?.trimmingCharacters(in: .whitespacesAndNewlines)
        let version = normalizedVersion?.isEmpty == false ? normalizedVersion! : fallbackSafariVersion
        return "Version/\(version) Safari/605.1.15"
    }

    public static func installedSafariVersion() -> String? {
        Bundle(path: "/Applications/Safari.app")?
            .object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
}
