import Testing
@testable import MusicDeckCore

@Suite("ログイン項目")
struct LoginItemControllerTests {
    @Test("有効化すると登録して設定を保存する")
    func enablingRegistersAndSaves() throws {
        let storage = InMemoryKeyValueStore()
        let manager = MockLoginItemManager()
        let controller = LoginItemController(
            manager: manager,
            settingsStore: SettingsStore(storage: storage)
        )

        let settings = try controller.setLaunchAtLogin(true)

        #expect(manager.registerCallCount == 1)
        #expect(manager.unregisterCallCount == 0)
        #expect(settings.launchAtLogin == true)
        #expect(controller.settings.launchAtLogin == true)
    }

    @Test("無効化すると登録解除して設定を保存する")
    func disablingUnregistersAndSaves() throws {
        let storage = InMemoryKeyValueStore()
        let manager = MockLoginItemManager()
        let controller = LoginItemController(
            manager: manager,
            settingsStore: SettingsStore(storage: storage)
        )

        let settings = try controller.setLaunchAtLogin(false)

        #expect(manager.registerCallCount == 0)
        #expect(manager.unregisterCallCount == 1)
        #expect(settings.launchAtLogin == false)
        #expect(controller.settings.launchAtLogin == false)
    }
}

private final class MockLoginItemManager: LoginItemManaging {
    var status: LoginItemStatus = .disabled
    var registerCallCount = 0
    var unregisterCallCount = 0

    func register() throws {
        registerCallCount += 1
        status = .enabled
    }

    func unregister() throws {
        unregisterCallCount += 1
        status = .disabled
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
