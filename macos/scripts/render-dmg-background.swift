#!/usr/bin/env swift
import AppKit
import Foundation
import ImageIO

/// Renders macos/packaging/dmg/background@2x.png from layout.sh (SF Pro Display + carrot arrow).

struct Layout {
    var bgWidth = 640
    var bgHeight = 368
    var iconSize = 128
    var appX = 140
    var appY = 200
    var appsX = 500
    var appsY = 200
    var bgHex = "F1F2EF"
    var inkHex = "1D1D1F"
    var accentHex = "FE6C19"
    var headline = "To install, drag CarrotType to Applications"
    var emphasis = "drag"
    var headlineSize: CGFloat = 26
    var headlineTop: CGFloat = 36
    var arrowStroke: CGFloat = 4
    var arrowInset: CGFloat = 16

    static func load(from path: String) throws -> Layout {
        let text = try String(contentsOfFile: path, encoding: .utf8)
        var values: [String: String] = [:]
        for raw in text.components(separatedBy: .newlines) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") { continue }
            let parts = line.split(separator: "=", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { continue }
            var value = parts[1]
            if value.hasPrefix("\""), value.hasSuffix("\""), value.count >= 2 {
                value = String(value.dropFirst().dropLast())
            }
            values[parts[0]] = value
        }
        var layout = Layout()
        if let v = values["DMG_BG_WIDTH"], let n = Int(v) { layout.bgWidth = n }
        if let v = values["DMG_BG_HEIGHT"], let n = Int(v) { layout.bgHeight = n }
        if let v = values["DMG_ICON_SIZE"], let n = Int(v) { layout.iconSize = n }
        if let v = values["DMG_APP_X"], let n = Int(v) { layout.appX = n }
        if let v = values["DMG_APP_Y"], let n = Int(v) { layout.appY = n }
        if let v = values["DMG_APPS_X"], let n = Int(v) { layout.appsX = n }
        if let v = values["DMG_APPS_Y"], let n = Int(v) { layout.appsY = n }
        if let v = values["DMG_BG_HEX"] { layout.bgHex = v }
        if let v = values["DMG_INK_HEX"] { layout.inkHex = v }
        if let v = values["DMG_ACCENT_HEX"] { layout.accentHex = v }
        if let v = values["DMG_HEADLINE"] { layout.headline = v }
        if let v = values["DMG_HEADLINE_EMPHASIS"] { layout.emphasis = v }
        if let v = values["DMG_HEADLINE_SIZE"], let n = Double(v) { layout.headlineSize = CGFloat(n) }
        if let v = values["DMG_HEADLINE_TOP"], let n = Double(v) { layout.headlineTop = CGFloat(n) }
        if let v = values["DMG_ARROW_STROKE"], let n = Double(v) { layout.arrowStroke = CGFloat(n) }
        if let v = values["DMG_ARROW_INSET"], let n = Double(v) { layout.arrowInset = CGFloat(n) }
        return layout
    }
}

func color(hex: String) -> NSColor {
    var cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
    if cleaned.count == 6 { cleaned += "FF" }
    var value: UInt64 = 0
    Scanner(string: cleaned).scanHexInt64(&value)
    let r = CGFloat((value >> 24) & 0xFF) / 255
    let g = CGFloat((value >> 16) & 0xFF) / 255
    let b = CGFloat((value >> 8) & 0xFF) / 255
    return NSColor(srgbRed: r, green: g, blue: b, alpha: 1)
}

func displayFont(size: CGFloat, italic: Bool) -> NSFont {
    let base = NSFont(name: "SF Pro Display", size: size)
        ?? NSFont.systemFont(ofSize: size, weight: .medium)
    if italic {
        return NSFontManager.shared.convert(base, toHaveTrait: .italicFontMask)
    }
    return base
}

func headline(layout: Layout) -> NSAttributedString {
    let result = NSMutableAttributedString(string: layout.headline)
    let full = NSRange(location: 0, length: result.length)
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    result.addAttributes([
        .font: displayFont(size: layout.headlineSize, italic: false),
        .foregroundColor: color(hex: layout.inkHex),
        .paragraphStyle: paragraph,
    ], range: full)
    let ns = layout.headline as NSString
    let emphasis = ns.range(of: layout.emphasis)
    if emphasis.location != NSNotFound {
        result.addAttribute(.font, value: displayFont(size: layout.headlineSize, italic: true), range: emphasis)
    }
    return result
}

func drawArrow(layout: Layout) {
    let half = CGFloat(layout.iconSize) / 2
    let y = CGFloat(layout.bgHeight) - CGFloat(layout.appY)
    let startX = CGFloat(layout.appX) + half + layout.arrowInset
    let endX = CGFloat(layout.appsX) - half - layout.arrowInset
    let head: CGFloat = 14
    let shaftEnd = endX - head + 1

    color(hex: layout.accentHex).set()
    let shaft = NSBezierPath()
    shaft.lineWidth = layout.arrowStroke
    shaft.lineCapStyle = .round
    shaft.move(to: NSPoint(x: startX, y: y))
    shaft.line(to: NSPoint(x: shaftEnd, y: y))
    shaft.stroke()

    let tip = NSBezierPath()
    tip.move(to: NSPoint(x: endX, y: y))
    tip.line(to: NSPoint(x: endX - head, y: y - 8))
    tip.line(to: NSPoint(x: endX - head, y: y + 8))
    tip.close()
    tip.fill()
}

let root = URL(fileURLWithPath: CommandLine.arguments[0])
    .resolvingSymlinksInPath()
    .deletingLastPathComponent() // scripts
    .deletingLastPathComponent() // macos
    .deletingLastPathComponent() // repo

var repo = FileManager.default.currentDirectoryPath
if CommandLine.arguments.count > 1 {
    repo = CommandLine.arguments[1]
} else {
    // Prefer walking up from this file when invoked as `swift macos/scripts/render-dmg-background.swift`
    repo = root.path
    if !FileManager.default.fileExists(atPath: repo + "/macos/packaging/dmg/layout.sh") {
        repo = FileManager.default.currentDirectoryPath
    }
}

let layoutPath = repo + "/macos/packaging/dmg/layout.sh"
let outputPath = repo + "/macos/packaging/dmg/background@2x.png"
let layout = try Layout.load(from: layoutPath)

let pixelsWide = layout.bgWidth * 2
let pixelsHigh = layout.bgHeight * 2
guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: pixelsWide,
    pixelsHigh: pixelsHigh,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fputs("ERROR: could not allocate bitmap\n", stderr)
    exit(1)
}
rep.size = NSSize(width: layout.bgWidth, height: layout.bgHeight)

NSGraphicsContext.saveGraphicsState()
guard let context = NSGraphicsContext(bitmapImageRep: rep) else {
    fputs("ERROR: could not create graphics context\n", stderr)
    exit(1)
}
NSGraphicsContext.current = context
let bounds = NSRect(x: 0, y: 0, width: layout.bgWidth, height: layout.bgHeight)
color(hex: layout.bgHex).setFill()
bounds.fill()

let text = headline(layout: layout)
let textHeight = layout.headlineSize * 1.3
let textRect = NSRect(
    x: 24,
    y: CGFloat(layout.bgHeight) - layout.headlineTop - textHeight,
    width: CGFloat(layout.bgWidth) - 48,
    height: textHeight + 4
)
text.draw(in: textRect)
drawArrow(layout: layout)
NSGraphicsContext.restoreGraphicsState()

let url = URL(fileURLWithPath: outputPath)
try FileManager.default.createDirectory(
    at: url.deletingLastPathComponent(),
    withIntermediateDirectories: true
)
guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil),
      let image = rep.cgImage else {
    fputs("ERROR: could not write PNG\n", stderr)
    exit(1)
}
let dpi: [CFString: Any] = [
    kCGImagePropertyDPIWidth: 144,
    kCGImagePropertyDPIHeight: 144,
    kCGImagePropertyPixelWidth: pixelsWide,
    kCGImagePropertyPixelHeight: pixelsHigh,
]
CGImageDestinationAddImage(dest, image, dpi as CFDictionary)
if !CGImageDestinationFinalize(dest) {
    fputs("ERROR: PNG finalize failed\n", stderr)
    exit(1)
}

print("OK: \(outputPath) (\(pixelsWide)x\(pixelsHigh) @144dpi)")
