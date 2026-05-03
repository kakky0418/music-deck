import Foundation
import MediaPlayer
import MusicDeckCore

@MainActor
final class RemoteCommandController {
    private let playerController: PlayerControlling
    private var commandTargets: [Any] = []

    init(playerController: PlayerControlling) {
        self.playerController = playerController
    }

    func start() {
        let center = MPRemoteCommandCenter.shared()

        center.togglePlayPauseCommand.isEnabled = true
        center.nextTrackCommand.isEnabled = true
        center.previousTrackCommand.isEnabled = true

        commandTargets.append(center.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.perform(.togglePlayPause)
            return .success
        })
        commandTargets.append(center.nextTrackCommand.addTarget { [weak self] _ in
            self?.perform(.nextTrack)
            return .success
        })
        commandTargets.append(center.previousTrackCommand.addTarget { [weak self] _ in
            self?.perform(.previousTrack)
            return .success
        })
    }

    private func perform(_ command: PlayerCommand) {
        Task { @MainActor in
            try? await playerController.perform(command)
        }
    }
}
