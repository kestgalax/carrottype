#!/usr/bin/env swift
import AppKit
import Foundation
import ImageIO

// Small deterministic renderer for our own SVG masters (M/L/H/V/C/Q/Z and g transforms).
// Unsupported syntax fails closed. The editable SVG is the source, not duplicated paths.
final class BrandRenderer: NSObject, XMLParserDelegate {
    let context: CGContext
    var failure: String?
    init(_ context: CGContext) { self.context = context }

    func parser(_ parser: XMLParser, didStartElement name: String, namespaceURI: String?, qualifiedName: String?, attributes a: [String: String]) {
        guard failure == nil else { return }
        if name == "g" {
            context.saveGState()
            if let transform = a["transform"] {
                let regex = try! NSRegularExpression(pattern: #"(translate|scale)\(([^)]+)\)"#)
                let range = NSRange(transform.startIndex..., in: transform)
                guard regex.stringByReplacingMatches(in: transform, range: range, withTemplate: "").trimmingCharacters(in: .whitespaces).isEmpty else {
                    failure = "Unsupported transform syntax"; return
                }
                for m in regex.matches(in: transform, range: range) {
                    let op = String(transform[Range(m.range(at: 1), in: transform)!])
                    let values = transform[Range(m.range(at: 2), in: transform)!].split { $0 == " " || $0 == "," }.compactMap { Double($0) }
                    if op == "translate", values.count == 2 { context.translateBy(x: values[0], y: values[1]) }
                    else if op == "scale", values.count == 1 { context.scaleBy(x: values[0], y: values[0]) }
                    else { failure = "Unsupported transform" }
                }
            }
        } else if name == "path", let d = a["d"], let fill = a["fill"], fill.hasPrefix("#"), fill.count == 7 {
            do {
                let path = try Self.path(d)
                let rgb = UInt32(fill.dropFirst(), radix: 16)!
                context.setFillColor(CGColor(srgbRed: Double((rgb >> 16) & 255)/255, green: Double((rgb >> 8) & 255)/255, blue: Double(rgb & 255)/255, alpha: 1))
                context.addPath(path); context.fillPath()
            } catch { failure = "Invalid path: \(error)" }
        } else if name != "svg" { failure = "Unsupported element \(name)" }
    }
    func parser(_ parser: XMLParser, didEndElement name: String, namespaceURI: String?, qualifiedName: String?) {
        if name == "g" { context.restoreGState() }
    }
    enum Invalid: Error { case path }
    static func path(_ d: String) throws -> CGPath {
        let regex = try NSRegularExpression(pattern: #"[A-Za-z]|[-+]?(?:\d*\.\d+|\d+)(?:[eE][-+]?\d+)?"#)
        let tokens = regex.matches(in: d, range: NSRange(d.startIndex..., in: d)).map { String(d[Range($0.range, in: d)!]) }
        var i = 0; var command = ""; let path = CGMutablePath()
        func n() throws -> CGFloat {
            guard i < tokens.count, let number = Double(tokens[i]) else { throw Invalid.path }
            i += 1; return number
        }
        func p() throws -> CGPoint { CGPoint(x: try n(), y: try n()) }
        while i < tokens.count {
            if tokens[i].first!.isLetter { command = tokens[i]; i += 1 }
            switch command {
            case "M": path.move(to: try p()); command = "L"
            case "L": path.addLine(to: try p())
            case "H": path.addLine(to: CGPoint(x: try n(), y: path.currentPoint.y))
            case "V": path.addLine(to: CGPoint(x: path.currentPoint.x, y: try n()))
            case "C": let a = try p(), b = try p(), end = try p(); path.addCurve(to: end, control1: a, control2: b)
            case "Q": let a = try p(), end = try p(); path.addQuadCurve(to: end, control: a)
            case "Z": path.closeSubpath(); command = ""
            default: throw Invalid.path
            }
        }
        return path
    }
}

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let source = root.appendingPathComponent("Brand/CarrotType-AppIcon.svg")
let output = root.appendingPathComponent("CarrotType/Assets.xcassets/AppIcon.appiconset")
for size in [16, 32, 64, 128, 256, 512, 1024] {
    let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: size * 4,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    context.translateBy(x: 0, y: CGFloat(size)); context.scaleBy(x: CGFloat(size)/64, y: -CGFloat(size)/64)
    let renderer = BrandRenderer(context)
    let parser = XMLParser(data: try Data(contentsOf: source)); parser.delegate = renderer
    guard parser.parse(), renderer.failure == nil else { fatalError(renderer.failure ?? "SVG XML failure") }
    let file = output.appendingPathComponent("icon_\(size)x\(size).png")
    let dest = CGImageDestinationCreateWithURL(file as CFURL, "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, context.makeImage()!, nil)
    guard CGImageDestinationFinalize(dest) else { fatalError("PNG export failed") }
}
print("Exported native app icons from editable CarrotType-AppIcon.svg")
