import Testing
@testable import MusicDeckCore

@Suite("ステータスバー表示方針")
struct StatusBarDisplayPolicyTests {
    @Test("短いタイトルと MusicDeck 用アイコンを使う")
    func usesVisibleShortTitleAndMusicDeckIcon() {
        #expect(StatusBarDisplayPolicy.title == "MD")
        #expect(StatusBarDisplayPolicy.templateImageName == "MenuBarIconTemplate")
        #expect(StatusBarDisplayPolicy.fallbackSymbolName == "music.note")
    }

    @Test("固定幅ではなく可変幅で表示する")
    func usesVariableLength() {
        #expect(StatusBarDisplayPolicy.usesVariableLength)
    }
}
