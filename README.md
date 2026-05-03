# MusicDeck

MusicDeck は、macOS で複数の音楽 Web アプリをまとめて扱う Swift 製ラッパーです。

## 要件

- macOS 14 以上
- Swift 6.0 以上
- Xcode Command Line Tools

## テスト

```bash
swift test
```

## `.app` の生成

```bash
bash scripts/build-app.sh
```

生成先は `.build/MusicDeck.app` です。

```bash
open ".build/MusicDeck.app"
```

## アイコン

- 生成元: `Resources/Assets/AppIcon-source.png`
- macOS 用アイコン: `Resources/AppIcon.icns`
- メニューバーアイコン生成元: `Resources/Assets/MenuBarIcon-source.png`
- メニューバー用 template PNG: `Resources/MenuBarIconTemplate.png`
- `bash scripts/build-app.sh` 実行時に `.app` へコピーされます。

## v1 の挙動

- Dock に表示し、ウィンドウを閉じても裏で常駐します。
- 左サイドバーから YouTube Music と Spotify を切り替えます。
- 各サービスは個別の `WKWebView` で開き、ログイン状態を保持します。
- YouTube Music のブラウザ判定に通すため、WKWebView の User-Agent に Safari 互換トークンを追加します。
- メニューバーのミニプレイヤーから、表示中の Now Playing に対して再生 / 一時停止、前へ、次へ、表示、ブラウザで開く、終了を操作できます。
- メディアキーは `MPRemoteCommandCenter` 経由で現在選択中のサービスに接続します。
- 「ログイン時に開く」は `SMAppService.mainApp` を使って切り替えます。

## Google ログインについて

Google OAuth は埋め込み WebView でブロックされる場合があります。ログイン画面で `disallowed_useragent` や embedded WebView policy のエラーが出た場合、この Swift/WKWebView 方式は v1 として不採用にして、Electron など別方式を検討します。
