import AppKit
import MusicDeckCore

@MainActor
final class ShellRootView: NSView {
    var theme = ShellTheme(service: .youtubeMusic) {
        didSet {
            needsDisplay = true
        }
    }

    override var isFlipped: Bool {
        true
    }

    override func draw(_ dirtyRect: NSRect) {
        theme.backgroundTop.setFill()
        dirtyRect.fill()

        let gradient = NSGradient(starting: theme.backgroundTop, ending: theme.backgroundBottom)
        gradient?.draw(in: bounds, angle: -90)

        theme.accent.withAlphaComponent(0.18).setFill()
        NSBezierPath(ovalIn: NSRect(x: -110, y: 40, width: 260, height: 260)).fill()

        theme.secondaryAccent.withAlphaComponent(0.10).setFill()
        NSBezierPath(ovalIn: NSRect(x: bounds.maxX - 240, y: bounds.maxY - 260, width: 320, height: 320)).fill()
    }
}

@MainActor
final class ShellWebFrameView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = 22
        layer?.cornerCurve = .continuous
        layer?.masksToBounds = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) は使用しません")
    }

    func apply(theme: ShellTheme) {
        layer?.backgroundColor = theme.elevatedSurface.cgColor
        layer?.borderWidth = 1
        layer?.borderColor = theme.border.cgColor
        shadow = NSShadow()
        shadow?.shadowColor = NSColor.black.withAlphaComponent(0.28)
        shadow?.shadowBlurRadius = 20
        shadow?.shadowOffset = NSSize(width: 0, height: -8)
    }
}

@MainActor
final class ShellSidebarView: NSView {
    private let services: [MusicService]
    private var theme = ShellTheme(service: .youtubeMusic)
    private var serviceButtons: [MusicService: ShellServiceButton] = [:]
    private let titleLabel = NSTextField(labelWithString: "MusicDeck")
    private let subtitleLabel = NSTextField(labelWithString: "")
    private let nowPlayingPanel = NSView()
    private let artworkView = NSImageView()
    private let nowPlayingTitleLabel = NSTextField(labelWithString: "待機中")
    private let nowPlayingArtistLabel = NSTextField(labelWithString: "再生するとここに表示されます")
    private let controlsStack = NSStackView()

    init(
        services: [MusicService],
        serviceTarget: AnyObject,
        serviceAction: Selector,
        commandTarget: AnyObject,
        previousAction: Selector,
        playPauseAction: Selector,
        nextAction: Selector
    ) {
        self.services = services
        super.init(frame: .zero)
        setup(
            serviceTarget: serviceTarget,
            serviceAction: serviceAction,
            commandTarget: commandTarget,
            previousAction: previousAction,
            playPauseAction: playPauseAction,
            nextAction: nextAction
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) は使用しません")
    }

    override var isFlipped: Bool {
        true
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.setFill()
        dirtyRect.fill()

        let gradient = NSGradient(
            colors: [
                theme.backgroundTop.withAlphaComponent(0.92),
                theme.backgroundBottom.withAlphaComponent(0.98)
            ]
        )
        gradient?.draw(in: bounds, angle: -90)
    }

    func apply(
        theme: ShellTheme,
        selectedService: MusicService,
        nowPlaying: NowPlayingSnapshot?,
        artwork: NSImage?
    ) {
        self.theme = theme
        needsDisplay = true

        titleLabel.textColor = theme.primaryText
        subtitleLabel.textColor = theme.secondaryText
        subtitleLabel.stringValue = selectedService.title

        for service in services {
            serviceButtons[service]?.apply(theme: theme, selected: service == selectedService)
        }

        nowPlayingPanel.layer?.backgroundColor = theme.elevatedSurface.cgColor
        nowPlayingPanel.layer?.borderColor = theme.border.cgColor
        nowPlayingTitleLabel.textColor = theme.primaryText
        nowPlayingArtistLabel.textColor = theme.secondaryText

        nowPlayingTitleLabel.stringValue = nonEmpty(nowPlaying?.title) ?? selectedService.title
        nowPlayingArtistLabel.stringValue = nonEmpty(nowPlaying?.artist) ?? "再生待機中"
        artworkView.image = artwork ?? servicePlaceholderImage(for: selectedService)

        for case let button as ShellControlButton in controlsStack.arrangedSubviews {
            button.apply(theme: theme)
        }
    }

    private func setup(
        serviceTarget: AnyObject,
        serviceAction: Selector,
        commandTarget: AnyObject,
        previousAction: Selector,
        playPauseAction: Selector,
        nextAction: Selector
    ) {
        wantsLayer = true

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 14
        stack.edgeInsets = NSEdgeInsets(top: 58, left: 18, bottom: 18, right: 18)

        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.lineBreakMode = .byTruncatingTail
        subtitleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        subtitleLabel.lineBreakMode = .byTruncatingTail

        let header = NSStackView()
        header.orientation = .vertical
        header.alignment = .leading
        header.spacing = 2
        header.addArrangedSubview(titleLabel)
        header.addArrangedSubview(subtitleLabel)
        stack.addArrangedSubview(header)

        let serviceStack = NSStackView()
        serviceStack.orientation = .vertical
        serviceStack.alignment = .leading
        serviceStack.spacing = 8
        for (index, service) in services.enumerated() {
            let button = ShellServiceButton(service: service, target: serviceTarget, action: serviceAction)
            button.tag = index
            button.widthAnchor.constraint(equalToConstant: 220).isActive = true
            button.heightAnchor.constraint(equalToConstant: 42).isActive = true
            serviceStack.addArrangedSubview(button)
            serviceButtons[service] = button
        }
        stack.addArrangedSubview(serviceStack)

        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .vertical)
        stack.addArrangedSubview(spacer)

        setupNowPlayingPanel(
            commandTarget: commandTarget,
            previousAction: previousAction,
            playPauseAction: playPauseAction,
            nextAction: nextAction
        )
        stack.addArrangedSubview(nowPlayingPanel)

        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            nowPlayingPanel.widthAnchor.constraint(equalToConstant: 220)
        ])
    }

    private func setupNowPlayingPanel(
        commandTarget: AnyObject,
        previousAction: Selector,
        playPauseAction: Selector,
        nextAction: Selector
    ) {
        nowPlayingPanel.wantsLayer = true
        nowPlayingPanel.layer?.cornerRadius = 18
        nowPlayingPanel.layer?.cornerCurve = .continuous
        nowPlayingPanel.layer?.borderWidth = 1

        artworkView.imageScaling = .scaleAxesIndependently
        artworkView.wantsLayer = true
        artworkView.layer?.cornerRadius = 12
        artworkView.layer?.cornerCurve = .continuous
        artworkView.layer?.masksToBounds = true

        nowPlayingTitleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        nowPlayingTitleLabel.lineBreakMode = .byTruncatingTail
        nowPlayingArtistLabel.font = .systemFont(ofSize: 11, weight: .medium)
        nowPlayingArtistLabel.lineBreakMode = .byTruncatingTail

        let labels = NSStackView()
        labels.orientation = .vertical
        labels.alignment = .leading
        labels.spacing = 3
        labels.addArrangedSubview(nowPlayingTitleLabel)
        labels.addArrangedSubview(nowPlayingArtistLabel)

        let topRow = NSStackView()
        topRow.orientation = .horizontal
        topRow.alignment = .centerY
        topRow.spacing = 10
        topRow.addArrangedSubview(artworkView)
        topRow.addArrangedSubview(labels)

        controlsStack.orientation = .horizontal
        controlsStack.alignment = .centerY
        controlsStack.distribution = .fillEqually
        controlsStack.spacing = 8
        controlsStack.addArrangedSubview(ShellControlButton(symbol: "backward.fill", target: commandTarget, action: previousAction))
        controlsStack.addArrangedSubview(ShellControlButton(symbol: "playpause.fill", target: commandTarget, action: playPauseAction))
        controlsStack.addArrangedSubview(ShellControlButton(symbol: "forward.fill", target: commandTarget, action: nextAction))

        let panelStack = NSStackView()
        panelStack.orientation = .vertical
        panelStack.alignment = .leading
        panelStack.spacing = 12
        panelStack.edgeInsets = NSEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        panelStack.addArrangedSubview(topRow)
        panelStack.addArrangedSubview(controlsStack)

        nowPlayingPanel.addSubview(panelStack)
        panelStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            artworkView.widthAnchor.constraint(equalToConstant: 54),
            artworkView.heightAnchor.constraint(equalToConstant: 54),
            labels.widthAnchor.constraint(equalToConstant: 128),
            controlsStack.widthAnchor.constraint(equalToConstant: 196),
            panelStack.leadingAnchor.constraint(equalTo: nowPlayingPanel.leadingAnchor),
            panelStack.trailingAnchor.constraint(equalTo: nowPlayingPanel.trailingAnchor),
            panelStack.topAnchor.constraint(equalTo: nowPlayingPanel.topAnchor),
            panelStack.bottomAnchor.constraint(equalTo: nowPlayingPanel.bottomAnchor)
        ])
    }

    private func nonEmpty(_ value: String?) -> String? {
        guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        return value
    }

    private func servicePlaceholderImage(for service: MusicService) -> NSImage {
        let image = NSImage(size: NSSize(width: 96, height: 96))
        image.lockFocus()
        let rect = NSRect(x: 0, y: 0, width: 96, height: 96)
        theme.accent.withAlphaComponent(0.90).setFill()
        NSBezierPath(roundedRect: rect, xRadius: 18, yRadius: 18).fill()
        theme.secondaryAccent.withAlphaComponent(0.45).setFill()
        NSBezierPath(ovalIn: NSRect(x: 42, y: -20, width: 76, height: 76)).fill()
        let symbol = NSImage(systemSymbolName: service.symbolName, accessibilityDescription: service.title)
        symbol?.isTemplate = true
        NSColor.white.withAlphaComponent(0.92).set()
        symbol?.draw(in: NSRect(x: 28, y: 28, width: 40, height: 40))
        image.unlockFocus()
        return image
    }
}

@MainActor
private final class ShellServiceButton: NSButton {
    private let service: MusicService
    private var theme = ShellTheme(service: .youtubeMusic)
    private var selectedService = false

    init(service: MusicService, target: AnyObject, action: Selector) {
        self.service = service
        super.init(frame: .zero)
        self.target = target
        self.action = action
        isBordered = false
        focusRingType = .none
        alignment = .left
        image = NSImage(systemSymbolName: service.symbolName, accessibilityDescription: service.title)
        image?.isTemplate = true
        imagePosition = .imageLeft
        setButtonType(.momentaryChange)
        wantsLayer = true
        layer?.cornerRadius = 12
        layer?.cornerCurve = .continuous
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) は使用しません")
    }

    override var isHighlighted: Bool {
        didSet {
            updateAppearance()
        }
    }

    func apply(theme: ShellTheme, selected: Bool) {
        self.theme = theme
        selectedService = selected
        updateAppearance()
    }

    private func updateAppearance() {
        let background = selectedService
            ? theme.selectedSurface
            : (isHighlighted ? theme.surface.withAlphaComponent(0.16) : theme.surface)
        let textColor = selectedService ? theme.primaryText : theme.secondaryText

        layer?.backgroundColor = background.cgColor
        layer?.borderWidth = selectedService ? 1 : 0
        layer?.borderColor = theme.accent.withAlphaComponent(0.42).cgColor
        contentTintColor = textColor
        attributedTitle = NSAttributedString(
            string: "  \(service.title)",
            attributes: [
                .font: NSFont.systemFont(ofSize: 14, weight: selectedService ? .semibold : .medium),
                .foregroundColor: textColor
            ]
        )
    }
}

@MainActor
private final class ShellControlButton: NSButton {
    init(symbol: String, target: AnyObject, action: Selector) {
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil) ?? NSImage()
        super.init(frame: .zero)
        self.image = image
        self.target = target
        self.action = action
        isBordered = false
        focusRingType = .none
        image.isTemplate = true
        imagePosition = .imageOnly
        wantsLayer = true
        layer?.cornerRadius = 10
        layer?.cornerCurve = .continuous
        heightAnchor.constraint(equalToConstant: 34).isActive = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) は使用しません")
    }

    override var isHighlighted: Bool {
        didSet {
            layer?.opacity = isHighlighted ? 0.72 : 1
        }
    }

    func apply(theme: ShellTheme) {
        layer?.backgroundColor = theme.surface.cgColor
        contentTintColor = theme.primaryText
    }
}
