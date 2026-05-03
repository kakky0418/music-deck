import Foundation

public protocol KeyValueStoring: AnyObject {
    func bool(forKey key: String) -> Bool
    func set(_ value: Bool, forKey key: String)
}

extension UserDefaults: KeyValueStoring {}

public final class SettingsStore {
    public static let launchAtLoginKey = "launchAtLogin"

    private let storage: KeyValueStoring

    public init(storage: KeyValueStoring = UserDefaults.standard) {
        self.storage = storage
    }

    public func load() -> AppSettings {
        AppSettings(
            launchAtLogin: storage.bool(forKey: Self.launchAtLoginKey)
        )
    }

    public func save(_ settings: AppSettings) {
        storage.set(settings.launchAtLogin, forKey: Self.launchAtLoginKey)
    }
}
