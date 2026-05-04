import Foundation

public struct NowPlayingDisplayState: Equatable, Sendable {
    public private(set) var selectedService: MusicService
    public private(set) var displayedService: MusicService
    public private(set) var snapshots: [MusicService: NowPlayingSnapshot]

    public init(initialService: MusicService) {
        selectedService = initialService
        displayedService = initialService
        snapshots = [:]
    }

    public var displayedSnapshot: NowPlayingSnapshot? {
        snapshots[displayedService]
    }

    public mutating func select(_ service: MusicService) {
        selectedService = service
        if displayedSnapshot == nil {
            displayedService = service
        }
    }

    public mutating func update(snapshot: NowPlayingSnapshot, for service: MusicService) {
        snapshots[service] = snapshot
        if snapshot.hasDisplayableContent {
            displayedService = service
        }
    }

    public mutating func clearSnapshot(for service: MusicService) {
        snapshots.removeValue(forKey: service)
        if displayedService == service {
            displayedService = selectedService
        }
    }
}
