import Foundation

@MainActor
public protocol PlayerControlling: AnyObject {
    func perform(_ command: PlayerCommand) async throws
}
