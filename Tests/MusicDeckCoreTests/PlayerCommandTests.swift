import Testing
@testable import MusicDeckCore

@Suite("プレイヤーコマンド")
struct PlayerCommandTests {
    @Test("再生と一時停止は play-pause ボタンをクリックする")
    func togglePlayPauseJavaScript() {
        let script = PlayerCommand.togglePlayPause.javaScript

        #expect(script.contains("play-pause-button"))
        #expect(script.contains("button.click()"))
    }

    @Test("次の曲は next ボタンをクリックする")
    func nextTrackJavaScript() {
        let script = PlayerCommand.nextTrack.javaScript

        #expect(script.contains("next-button"))
        #expect(script.contains("button.click()"))
    }

    @Test("前の曲は previous ボタンをクリックする")
    func previousTrackJavaScript() {
        let script = PlayerCommand.previousTrack.javaScript

        #expect(script.contains("previous-button"))
        #expect(script.contains("button.click()"))
    }
}
