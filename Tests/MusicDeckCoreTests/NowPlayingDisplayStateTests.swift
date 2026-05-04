import Testing
@testable import MusicDeckCore

@Suite("再生中表示状態")
struct NowPlayingDisplayStateTests {
    @Test("サービス切替だけでは再生中表示を変えない")
    func serviceSelectionDoesNotReplaceDisplayedTrack() {
        var state = NowPlayingDisplayState(initialService: .youtubeMusic)
        let snapshot = NowPlayingSnapshot(title: "ふわふわ時間", artist: "桜高軽音部", artworkURL: "https://example.com/art.jpg")

        state.update(snapshot: snapshot, for: .youtubeMusic)
        state.select(.spotify)

        #expect(state.displayedService == .youtubeMusic)
        #expect(state.displayedSnapshot == snapshot)
    }

    @Test("曲情報を取得したサービスへ再生中表示を切り替える")
    func displayFollowsLatestTrackSnapshot() {
        var state = NowPlayingDisplayState(initialService: .youtubeMusic)
        let youtubeSnapshot = NowPlayingSnapshot(title: "ふわふわ時間", artist: "桜高軽音部", artworkURL: "")
        let spotifySnapshot = NowPlayingSnapshot(title: "Night Dancer", artist: "imase", artworkURL: "")

        state.update(snapshot: youtubeSnapshot, for: .youtubeMusic)
        state.update(snapshot: spotifySnapshot, for: .spotify)

        #expect(state.displayedService == .spotify)
        #expect(state.displayedSnapshot == spotifySnapshot)
    }

    @Test("曲情報がない場合は選択中サービスの fallback 表示にする")
    func selectedServiceFallbackWhenNoTrack() {
        var state = NowPlayingDisplayState(initialService: .youtubeMusic)

        state.select(.spotify)

        #expect(state.displayedService == .spotify)
        #expect(state.displayedSnapshot == nil)
    }

    @Test("曲情報が取れなくなったサービスは古い表示を消す")
    func clearingSnapshotRemovesStaleTrack() {
        var state = NowPlayingDisplayState(initialService: .amazonMusic)
        let snapshot = NowPlayingSnapshot(title: "IRIS OUT", artist: "米津玄師", artworkURL: "")

        state.update(snapshot: snapshot, for: .amazonMusic)
        state.clearSnapshot(for: .amazonMusic)

        #expect(state.displayedService == .amazonMusic)
        #expect(state.displayedSnapshot == nil)
    }
}
