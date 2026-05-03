import Testing
@testable import MusicDeckCore

@Suite("設定ストア")
struct SettingsStoreTests {
    @Test("初期設定ではログイン時起動が無効")
    func defaultLaunchAtLoginIsDisabled() {
        let store = SettingsStore(storage: InMemoryKeyValueStore())

        #expect(store.load().launchAtLogin == false)
    }

    @Test("ログイン時起動の設定を保存して読み出せる")
    func savesLaunchAtLogin() {
        let storage = InMemoryKeyValueStore()
        let store = SettingsStore(storage: storage)

        store.save(AppSettings(launchAtLogin: true))

        #expect(store.load().launchAtLogin == true)
    }
}

private final class InMemoryKeyValueStore: KeyValueStoring {
    private var values: [String: Bool] = [:]

    func bool(forKey key: String) -> Bool {
        values[key] ?? false
    }

    func set(_ value: Bool, forKey key: String) {
        values[key] = value
    }
}
