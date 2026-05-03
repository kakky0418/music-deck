import Foundation

public struct ServiceThemePreset: Equatable, Sendable {
    public let accentHex: String
    public let secondaryAccentHex: String
    public let backgroundHex: String

    public init(accentHex: String, secondaryAccentHex: String, backgroundHex: String) {
        self.accentHex = accentHex
        self.secondaryAccentHex = secondaryAccentHex
        self.backgroundHex = backgroundHex
    }
}

