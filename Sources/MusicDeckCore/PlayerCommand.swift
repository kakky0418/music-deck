import Foundation

public enum PlayerCommand: Equatable, Sendable {
    case togglePlayPause
    case nextTrack
    case previousTrack

    public var javaScript: String {
        MusicService.youtubeMusic.javaScript(for: self)
    }
}
