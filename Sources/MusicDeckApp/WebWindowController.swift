import AppKit
import WebKit
import MusicDeckCore

@MainActor
final class WebWindowController: NSWindowController, WKNavigationDelegate, WKUIDelegate, PlayerControlling {
    private let services = MusicService.allCases
    private var selectedService: MusicService = .youtubeMusic
    private var webViews: [MusicService: WKWebView] = [:]
    private var webViewServices: [ObjectIdentifier: MusicService] = [:]
    private var loadedServices = Set<MusicService>()
    private var nowPlayingDisplayState = NowPlayingDisplayState(initialService: .youtubeMusic)
    private var artworkImages: [MusicService: NSImage] = [:]
    private var artworkColors: [MusicService: NSColor] = [:]
    private var artworkURLs: [MusicService: String] = [:]
    private var nowPlayingPollTask: Task<Void, Never>?
    private let rootView = ShellRootView()
    private var sidebarView: ShellSidebarView!
    private let webFrameView = ShellWebFrameView()
    private let contentContainer = NSView()

    var activeService: MusicService {
        selectedService
    }

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1240, height: 780),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "MusicDeck"
        window.minSize = NSSize(width: 860, height: 560)
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.backgroundColor = .clear
        window.center()

        super.init(window: window)

        window.contentView = makeRootView()
        window.delegate = self
        selectService(.youtubeMusic)
    }

    deinit {
        nowPlayingPollTask?.cancel()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) は使用しません")
    }

    func showAndLoad() {
        showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        loadSelectedServiceIfNeeded()
        startNowPlayingPolling()
    }

    func toggleVisibility() {
        guard let window else {
            return
        }

        if window.isVisible {
            window.orderOut(nil)
        } else {
            showAndLoad()
        }
    }

    func openCurrentPageInBrowser() {
        let currentWebView = webView(for: selectedService)
        NSWorkspace.shared.open(
            NavigationPolicy.browserOpenURL(
                currentURL: currentWebView.url,
                fallbackURL: selectedService.homeURL
            )
        )
    }

    func perform(_ command: PlayerCommand) async throws {
        try await perform(command, on: selectedService)
    }

    func performNowPlaying(_ command: PlayerCommand) async throws {
        try await perform(command, on: nowPlayingDisplayState.displayedService)
    }

    private func perform(_ command: PlayerCommand, on service: MusicService) async throws {
        let webView = webView(for: service)
        let script = service.javaScript(for: command)
        _ = try await webView.evaluateJavaScript(script)
    }

    private func makeRootView() -> NSView {
        sidebarView = ShellSidebarView(
            services: services,
            serviceTarget: self,
            serviceAction: #selector(selectServiceFromButton(_:)),
            commandTarget: self,
            previousAction: #selector(previousTrackFromShell),
            playPauseAction: #selector(togglePlayPauseFromShell),
            nextAction: #selector(nextTrackFromShell)
        )
        rootView.addSubview(sidebarView)
        rootView.addSubview(webFrameView)
        webFrameView.addSubview(contentContainer)

        sidebarView.translatesAutoresizingMaskIntoConstraints = false
        webFrameView.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            sidebarView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
            sidebarView.topAnchor.constraint(equalTo: rootView.topAnchor),
            sidebarView.bottomAnchor.constraint(equalTo: rootView.bottomAnchor),
            sidebarView.widthAnchor.constraint(equalToConstant: 256),

            webFrameView.leadingAnchor.constraint(equalTo: sidebarView.trailingAnchor),
            webFrameView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor, constant: -14),
            webFrameView.topAnchor.constraint(equalTo: rootView.topAnchor, constant: 14),
            webFrameView.bottomAnchor.constraint(equalTo: rootView.bottomAnchor, constant: -14),

            contentContainer.leadingAnchor.constraint(equalTo: webFrameView.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: webFrameView.trailingAnchor),
            contentContainer.topAnchor.constraint(equalTo: webFrameView.topAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: webFrameView.bottomAnchor)
        ])

        return rootView
    }

    @objc private func selectServiceFromButton(_ sender: NSButton) {
        guard services.indices.contains(sender.tag) else {
            return
        }

        selectService(services[sender.tag])
    }

    private func selectService(_ service: MusicService) {
        selectedService = service
        nowPlayingDisplayState.select(service)
        window?.title = service.title

        showWebView(for: service)
        loadSelectedServiceIfNeeded()
        applyShellTheme()

        Task { @MainActor in
            await refreshNowPlaying(for: service)
        }
    }

    private func showWebView(for service: MusicService) {
        let selectedWebView = webView(for: service)

        for subview in contentContainer.subviews where subview !== selectedWebView {
            subview.removeFromSuperview()
        }

        if selectedWebView.superview !== contentContainer {
            contentContainer.addSubview(selectedWebView)
            selectedWebView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                selectedWebView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
                selectedWebView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
                selectedWebView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
                selectedWebView.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor)
            ])
        }
    }

    private func webView(for service: MusicService) -> WKWebView {
        if let webView = webViews[service] {
            return webView
        }

        let webView = WKWebView(frame: .zero, configuration: makeConfiguration())
        webView.allowsMagnification = false
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.wantsLayer = true

        webViews[service] = webView
        webViewServices[ObjectIdentifier(webView)] = service
        return webView
    }

    private func makeConfiguration() -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.allowsAirPlayForMediaPlayback = true
        configuration.applicationNameForUserAgent = UserAgentPolicy.safariCompatibleApplicationName(
            safariVersion: UserAgentPolicy.installedSafariVersion()
        )
        return configuration
    }

    private func loadSelectedServiceIfNeeded() {
        guard !loadedServices.contains(selectedService) else {
            return
        }

        loadedServices.insert(selectedService)
        webView(for: selectedService).load(URLRequest(url: selectedService.homeURL))
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        let isMainFrame = navigationAction.targetFrame?.isMainFrame ?? true

        switch NavigationPolicy.decision(for: url, isMainFrame: isMainFrame) {
        case .allowInApp:
            decisionHandler(.allow)
        case .openExternally:
            NSWorkspace.shared.open(url)
            decisionHandler(.cancel)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        detectAuthBlock(in: webView)
        Task { @MainActor in
            await refreshNowPlaying(for: service(for: webView))
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        presentLoadError(error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        presentLoadError(error)
    }

    private func detectAuthBlock(in webView: WKWebView) {
        webView.evaluateJavaScript("document.body ? document.body.innerText : ''") { [weak self, weak webView] result, _ in
            guard let self, let webView, let text = result as? String else {
                return
            }

            if AuthBlockDetector.isBlocked(text: text, url: webView.url) {
                self.presentAuthBlocked(service: self.service(for: webView))
            }
        }
    }

    private func service(for webView: WKWebView) -> MusicService {
        webViewServices[ObjectIdentifier(webView)] ?? selectedService
    }

    private func presentAuthBlocked(service: MusicService) {
        let alert = NSAlert()
        alert.messageText = "\(service.title) のログインがブロックされました"
        alert.informativeText = "WKWebView で認証フローが許可されていない可能性があります。既定のブラウザで開いて確認してください。"
        alert.addButton(withTitle: "ブラウザで開く")
        alert.addButton(withTitle: "閉じる")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            openCurrentPageInBrowser()
        }
    }

    private func presentLoadError(_ error: Error) {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
            return
        }

        let alert = NSAlert(error: error)
        alert.messageText = "ページを読み込めません"
        alert.addButton(withTitle: "閉じる")
        alert.runModal()
    }

    private func activeShellTheme() -> ShellTheme {
        ShellTheme(service: selectedService, artworkColor: artworkColors[nowPlayingDisplayState.displayedService])
    }

    func currentShellTheme() -> ShellTheme {
        activeShellTheme()
    }

    func currentNowPlaying() -> NowPlayingSnapshot? {
        nowPlayingDisplayState.displayedSnapshot
    }

    func currentArtwork() -> NSImage? {
        artworkImages[nowPlayingDisplayState.displayedService]
    }

    private func applyShellTheme() {
        let theme = activeShellTheme()
        rootView.theme = theme
        webFrameView.apply(theme: theme)
        sidebarView.apply(
            theme: theme,
            selectedService: selectedService,
            nowPlaying: nowPlayingDisplayState.displayedSnapshot,
            artwork: artworkImages[nowPlayingDisplayState.displayedService]
        )
    }

    private func startNowPlayingPolling() {
        guard nowPlayingPollTask == nil else {
            return
        }

        nowPlayingPollTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                await self?.refreshNowPlaying()
                try? await Task.sleep(nanoseconds: 8_000_000_000)
            }
        }
    }

    private func refreshNowPlaying(for service: MusicService? = nil) async {
        let service = service ?? selectedService
        guard loadedServices.contains(service) else {
            if service == selectedService {
                applyShellTheme()
            }
            return
        }

        let webView = webView(for: service)
        guard
            let result = try? await webView.evaluateJavaScript(NowPlayingExtractionScript.javaScript(for: service)),
            let json = result as? String,
            let data = json.data(using: .utf8),
            let snapshot = try? JSONDecoder().decode(NowPlayingSnapshot.self, from: data),
            snapshot.hasDisplayableContent
        else {
            if service == selectedService {
                applyShellTheme()
            }
            return
        }

        nowPlayingDisplayState.update(snapshot: snapshot, for: service)
        if service == selectedService || service == nowPlayingDisplayState.displayedService {
            applyShellTheme()
        }

        await refreshArtworkIfNeeded(for: service, snapshot: snapshot)
    }

    private func refreshArtworkIfNeeded(for service: MusicService, snapshot: NowPlayingSnapshot) async {
        guard
            !snapshot.artworkURL.isEmpty,
            artworkURLs[service] != snapshot.artworkURL,
            let url = URL(string: snapshot.artworkURL)
        else {
            return
        }

        artworkURLs[service] = snapshot.artworkURL

        guard
            let (data, _) = try? await URLSession.shared.data(from: url),
            let image = NSImage(data: data)
        else {
            return
        }

        artworkImages[service] = image
        artworkColors[service] = ArtworkColorExtractor.dominantColor(from: data)

        if service == selectedService || service == nowPlayingDisplayState.displayedService {
            applyShellTheme()
        }
    }

    @objc private func togglePlayPauseFromShell() {
        performFromShell(.togglePlayPause)
    }

    @objc private func nextTrackFromShell() {
        performFromShell(.nextTrack)
    }

    @objc private func previousTrackFromShell() {
        performFromShell(.previousTrack)
    }

    private func performFromShell(_ command: PlayerCommand) {
        Task { @MainActor in
            do {
                let service = nowPlayingDisplayState.displayedService
                try await perform(command, on: service)
                await refreshNowPlaying(for: service)
            } catch {
                NSAlert(error: error).runModal()
            }
        }
    }
}

extension WebWindowController: NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }
}
