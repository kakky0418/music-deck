import AppKit
import MusicDeckCore

@MainActor
final class StatusBarController: NSObject {
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private let viewController: StatusPopoverViewController

    init(
        webWindowController: WebWindowController,
        loginItemController: LoginItemController
    ) {
        statusItem = NSStatusBar.system.statusItem(
            withLength: StatusBarDisplayPolicy.usesVariableLength
                ? NSStatusItem.variableLength
                : NSStatusItem.squareLength
        )
        popover = NSPopover()
        viewController = StatusPopoverViewController(
            webWindowController: webWindowController,
            loginItemController: loginItemController
        )

        super.init()

        popover.behavior = .transient
        popover.contentSize = NSSize(width: 300, height: 236)
        popover.contentViewController = viewController

        if let button = statusItem.button {
            button.image = statusBarImage()
            button.title = StatusBarDisplayPolicy.title
            button.imagePosition = .imageLeft
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
    }

    private func statusBarImage() -> NSImage? {
        let image = NSImage(named: NSImage.Name(StatusBarDisplayPolicy.templateImageName))
            ?? NSImage(
                systemSymbolName: StatusBarDisplayPolicy.fallbackSymbolName,
                accessibilityDescription: "MusicDeck"
            )
        image?.isTemplate = true
        image?.size = NSSize(width: 18, height: 18)
        return image
    }

    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            viewController.refresh()
        }
    }
}

@MainActor
private final class StatusPopoverViewController: NSViewController {
    private let webWindowController: WebWindowController
    private let loginItemController: LoginItemController
    private var rootStack: NSStackView!
    private var artworkView: NSImageView!
    private var titleLabel: NSTextField!
    private var subtitleLabel: NSTextField!
    private var launchAtLoginButton: NSButton!
    private var themedButtons: [NSButton] = []

    init(
        webWindowController: WebWindowController,
        loginItemController: LoginItemController
    ) {
        self.webWindowController = webWindowController
        self.loginItemController = loginItemController
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) は使用しません")
    }

    override func loadView() {
        let root = NSStackView()
        rootStack = root
        root.orientation = .vertical
        root.alignment = .leading
        root.spacing = 12
        root.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        root.wantsLayer = true
        root.layer?.cornerRadius = 18
        root.layer?.cornerCurve = .continuous

        artworkView = NSImageView()
        artworkView.imageScaling = .scaleAxesIndependently
        artworkView.wantsLayer = true
        artworkView.layer?.cornerRadius = 12
        artworkView.layer?.cornerCurve = .continuous
        artworkView.layer?.masksToBounds = true

        titleLabel = NSTextField(labelWithString: "")
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.lineBreakMode = .byTruncatingTail
        subtitleLabel = NSTextField(labelWithString: "")
        subtitleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        subtitleLabel.lineBreakMode = .byTruncatingTail

        let labels = NSStackView()
        labels.orientation = .vertical
        labels.alignment = .leading
        labels.spacing = 4
        labels.addArrangedSubview(titleLabel)
        labels.addArrangedSubview(subtitleLabel)

        let nowPlayingRow = NSStackView()
        nowPlayingRow.orientation = .horizontal
        nowPlayingRow.alignment = .centerY
        nowPlayingRow.spacing = 12
        nowPlayingRow.addArrangedSubview(artworkView)
        nowPlayingRow.addArrangedSubview(labels)

        let controls = NSStackView()
        controls.orientation = .horizontal
        controls.alignment = .centerY
        controls.spacing = 10
        controls.addArrangedSubview(iconButton(symbol: "backward.fill", action: #selector(previousTrack)))
        controls.addArrangedSubview(iconButton(symbol: "playpause.fill", action: #selector(togglePlayPause)))
        controls.addArrangedSubview(iconButton(symbol: "forward.fill", action: #selector(nextTrack)))

        let windowActions = NSStackView()
        windowActions.orientation = .horizontal
        windowActions.alignment = .centerY
        windowActions.spacing = 8
        windowActions.addArrangedSubview(textButton(title: "表示", action: #selector(toggleWindow)))
        windowActions.addArrangedSubview(textButton(title: "ブラウザ", action: #selector(openInBrowser)))
        windowActions.addArrangedSubview(textButton(title: "終了", action: #selector(quit)))

        launchAtLoginButton = NSButton(
            checkboxWithTitle: "ログイン時に開く",
            target: self,
            action: #selector(toggleLaunchAtLogin)
        )

        root.addArrangedSubview(nowPlayingRow)
        root.addArrangedSubview(controls)
        root.addArrangedSubview(windowActions)
        root.addArrangedSubview(launchAtLoginButton)
        view = root

        NSLayoutConstraint.activate([
            artworkView.widthAnchor.constraint(equalToConstant: 58),
            artworkView.heightAnchor.constraint(equalToConstant: 58),
            labels.widthAnchor.constraint(equalToConstant: 190),
            controls.widthAnchor.constraint(equalToConstant: 268),
            windowActions.widthAnchor.constraint(equalToConstant: 268)
        ])

        refresh()
    }

    func refresh() {
        guard isViewLoaded else {
            return
        }

        launchAtLoginButton.state = loginItemController.settings.launchAtLogin ? .on : .off
        let theme = webWindowController.currentShellTheme()
        let nowPlaying = webWindowController.currentNowPlaying()
        rootStack.layer?.backgroundColor = theme.backgroundBottom.shellMixed(with: theme.accent, fraction: 0.16).cgColor
        titleLabel.textColor = theme.primaryText
        subtitleLabel.textColor = theme.secondaryText
        launchAtLoginButton.contentTintColor = theme.secondaryText
        artworkView.image = webWindowController.currentArtwork() ?? placeholderImage(theme: theme)
        titleLabel.stringValue = nonEmpty(nowPlaying?.title) ?? webWindowController.activeService.title
        subtitleLabel.stringValue = nonEmpty(nowPlaying?.artist) ?? "MusicDeck"

        for button in themedButtons {
            button.layer?.backgroundColor = theme.surface.cgColor
            button.contentTintColor = theme.primaryText
        }
    }

    private func iconButton(symbol: String, action: Selector) -> NSButton {
        let button = NSButton(image: NSImage(systemSymbolName: symbol, accessibilityDescription: nil) ?? NSImage(), target: self, action: action)
        button.isBordered = false
        button.focusRingType = .none
        button.imagePosition = .imageOnly
        button.wantsLayer = true
        button.layer?.cornerRadius = 11
        button.layer?.cornerCurve = .continuous
        button.widthAnchor.constraint(equalToConstant: 84).isActive = true
        button.heightAnchor.constraint(equalToConstant: 38).isActive = true
        themedButtons.append(button)
        return button
    }

    private func textButton(title: String, action: Selector) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.isBordered = false
        button.focusRingType = .none
        button.wantsLayer = true
        button.layer?.cornerRadius = 10
        button.layer?.cornerCurve = .continuous
        button.font = .systemFont(ofSize: 12, weight: .semibold)
        button.widthAnchor.constraint(equalToConstant: 84).isActive = true
        button.heightAnchor.constraint(equalToConstant: 34).isActive = true
        themedButtons.append(button)
        return button
    }

    private func nonEmpty(_ value: String?) -> String? {
        guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        return value
    }

    private func placeholderImage(theme: ShellTheme) -> NSImage {
        let image = NSImage(size: NSSize(width: 96, height: 96))
        image.lockFocus()
        theme.accent.setFill()
        NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: 96, height: 96), xRadius: 18, yRadius: 18).fill()
        theme.secondaryAccent.withAlphaComponent(0.46).setFill()
        NSBezierPath(ovalIn: NSRect(x: 38, y: -18, width: 80, height: 80)).fill()
        let symbol = NSImage(systemSymbolName: webWindowController.activeService.symbolName, accessibilityDescription: nil)
        symbol?.isTemplate = true
        NSColor.white.withAlphaComponent(0.92).set()
        symbol?.draw(in: NSRect(x: 28, y: 28, width: 40, height: 40))
        image.unlockFocus()
        return image
    }

    @objc private func togglePlayPause() {
        perform(.togglePlayPause)
    }

    @objc private func nextTrack() {
        perform(.nextTrack)
    }

    @objc private func previousTrack() {
        perform(.previousTrack)
    }

    @objc private func toggleWindow() {
        webWindowController.toggleVisibility()
    }

    @objc private func openInBrowser() {
        webWindowController.openCurrentPageInBrowser()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            let enabled = launchAtLoginButton.state == .on
            _ = try loginItemController.setLaunchAtLogin(enabled)
        } catch {
            launchAtLoginButton.state = loginItemController.settings.launchAtLogin ? .on : .off
            NSAlert(error: error).runModal()
        }
    }

    private func perform(_ command: PlayerCommand) {
        Task { @MainActor in
            do {
                try await webWindowController.performNowPlaying(command)
            } catch {
                NSAlert(error: error).runModal()
            }
        }
    }
}
