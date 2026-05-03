import Foundation
#if canImport(ServiceManagement)
import ServiceManagement
#endif

public enum LoginItemStatus: Equatable {
    case enabled
    case disabled
    case requiresApproval
    case unavailable
}

public protocol LoginItemManaging: AnyObject {
    var status: LoginItemStatus { get }
    func register() throws
    func unregister() throws
}

public final class LoginItemController {
    private let manager: LoginItemManaging
    private let settingsStore: SettingsStore

    public init(manager: LoginItemManaging, settingsStore: SettingsStore) {
        self.manager = manager
        self.settingsStore = settingsStore
    }

    public var settings: AppSettings {
        settingsStore.load()
    }

    public var status: LoginItemStatus {
        manager.status
    }

    @discardableResult
    public func setLaunchAtLogin(_ enabled: Bool) throws -> AppSettings {
        if enabled {
            try manager.register()
        } else {
            try manager.unregister()
        }

        let settings = AppSettings(launchAtLogin: enabled)
        settingsStore.save(settings)
        return settings
    }
}

#if canImport(ServiceManagement)
@available(macOS 13.0, *)
public final class MainAppLoginItemManager: LoginItemManaging {
    public init() {}

    public var status: LoginItemStatus {
        switch SMAppService.mainApp.status {
        case .enabled:
            return .enabled
        case .requiresApproval:
            return .requiresApproval
        case .notRegistered, .notFound:
            return .disabled
        @unknown default:
            return .unavailable
        }
    }

    public func register() throws {
        try SMAppService.mainApp.register()
    }

    public func unregister() throws {
        try SMAppService.mainApp.unregister()
    }
}
#endif
