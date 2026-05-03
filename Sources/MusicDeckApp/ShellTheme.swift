import AppKit
import MusicDeckCore

struct ShellTheme {
    let service: MusicService
    let accent: NSColor
    let secondaryAccent: NSColor
    let backgroundTop: NSColor
    let backgroundBottom: NSColor
    let surface: NSColor
    let elevatedSurface: NSColor
    let selectedSurface: NSColor
    let border: NSColor
    let primaryText: NSColor
    let secondaryText: NSColor

    init(service: MusicService, artworkColor: NSColor? = nil) {
        self.service = service

        let preset = service.themePreset
        let fallbackAccent = NSColor.shellHex(preset.accentHex)
        let fallbackSecondary = NSColor.shellHex(preset.secondaryAccentHex)
        let baseAccent = artworkColor?.shellReadableAccent ?? fallbackAccent
        let background = NSColor.shellHex(preset.backgroundHex)

        accent = baseAccent
        secondaryAccent = artworkColor?.shellMixed(with: fallbackSecondary, fraction: 0.36) ?? fallbackSecondary
        backgroundTop = background.shellMixed(with: baseAccent, fraction: 0.28).shellMixed(with: .black, fraction: 0.36)
        backgroundBottom = background.shellMixed(with: .black, fraction: 0.48)
        surface = NSColor.white.withAlphaComponent(0.08)
        elevatedSurface = NSColor.white.withAlphaComponent(0.12)
        selectedSurface = baseAccent.withAlphaComponent(0.28)
        border = NSColor.white.withAlphaComponent(0.14)
        primaryText = NSColor.white.withAlphaComponent(0.94)
        secondaryText = NSColor.white.withAlphaComponent(0.62)
    }
}

extension NSColor {
    static func shellHex(_ hex: String) -> NSColor {
        let value = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard value.count == 6, let integer = Int(value, radix: 16) else {
            return .white
        }

        let red = CGFloat((integer >> 16) & 0xff) / 255
        let green = CGFloat((integer >> 8) & 0xff) / 255
        let blue = CGFloat(integer & 0xff) / 255
        return NSColor(srgbRed: red, green: green, blue: blue, alpha: 1)
    }

    var shellReadableAccent: NSColor {
        let components = shellComponents
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        NSColor(
            srgbRed: components.red,
            green: components.green,
            blue: components.blue,
            alpha: components.alpha
        ).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        return NSColor(
            hue: hue,
            saturation: max(0.42, saturation),
            brightness: min(0.92, max(0.48, brightness)),
            alpha: 1
        )
    }

    func shellMixed(with color: NSColor, fraction: CGFloat) -> NSColor {
        let first = shellComponents
        let second = color.shellComponents
        let clampedFraction = max(0, min(1, fraction))
        let inverse = 1 - clampedFraction

        return NSColor(
            srgbRed: first.red * inverse + second.red * clampedFraction,
            green: first.green * inverse + second.green * clampedFraction,
            blue: first.blue * inverse + second.blue * clampedFraction,
            alpha: first.alpha * inverse + second.alpha * clampedFraction
        )
    }

    private var shellComponents: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        let color = usingColorSpace(.sRGB) ?? self
        return (color.redComponent, color.greenComponent, color.blueComponent, color.alphaComponent)
    }
}

enum ArtworkColorExtractor {
    static func dominantColor(from data: Data) -> NSColor? {
        guard
            let image = NSImage(data: data),
            let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else {
            return nil
        }

        let size = 36
        let bytesPerPixel = 4
        let bytesPerRow = size * bytesPerPixel
        var pixels = [UInt8](repeating: 0, count: size * size * bytesPerPixel)
        guard
            let context = CGContext(
                data: &pixels,
                width: size,
                height: size,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else {
            return nil
        }

        context.interpolationQuality = .medium
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size, height: size))

        var redTotal: CGFloat = 0
        var greenTotal: CGFloat = 0
        var blueTotal: CGFloat = 0
        var weightTotal: CGFloat = 0

        for index in stride(from: 0, to: pixels.count, by: bytesPerPixel) {
            let alpha = CGFloat(pixels[index + 3]) / 255
            guard alpha > 0.25 else {
                continue
            }

            let red = CGFloat(pixels[index]) / 255
            let green = CGFloat(pixels[index + 1]) / 255
            let blue = CGFloat(pixels[index + 2]) / 255
            let maxChannel = max(red, green, blue)
            let minChannel = min(red, green, blue)
            let saturation = maxChannel - minChannel
            let brightness = (red + green + blue) / 3
            guard brightness > 0.08, brightness < 0.94 else {
                continue
            }

            let weight = alpha * (0.32 + saturation)
            redTotal += red * weight
            greenTotal += green * weight
            blueTotal += blue * weight
            weightTotal += weight
        }

        guard weightTotal > 0 else {
            return nil
        }

        return NSColor(
            srgbRed: redTotal / weightTotal,
            green: greenTotal / weightTotal,
            blue: blueTotal / weightTotal,
            alpha: 1
        )
    }
}

