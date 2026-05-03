import Foundation

public struct AppSettings: Equatable, Codable {
    public var launchAtLogin: Bool

    public init(launchAtLogin: Bool = false) {
        self.launchAtLogin = launchAtLogin
    }
}
