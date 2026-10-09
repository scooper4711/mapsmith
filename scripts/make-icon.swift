#!/usr/bin/env swift
// Draws the app icon (a parchment battle map split into print tiles, with a compass rose)
// and writes a 1024 px PNG. Usage: swift scripts/make-icon.swift <output.png>
import AppKit
import CoreGraphics

let size: CGFloat = 1024
let body = CGRect(x: 100, y: 100, width: 824, height: 824)
let cornerRadius: CGFloat = 185

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}

func drawBackground(_ context: CGContext) {
    let shape = CGPath(roundedRect: body, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: color(0x000000, 0.35))
    context.addPath(shape)
    context.setFillColor(color(0xE9D3A4))
    context.fillPath()
    context.restoreGState()

    context.addPath(shape)
    context.clip()
    let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                              colors: [color(0xF6E8C6), color(0xDDC08A)] as CFArray, locations: [0, 1])!
    context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: body.maxY), end: CGPoint(x: 0, y: body.minY),
                               options: [])
}

func drawTerrain(_ context: CGContext) {
    // Sea along the bottom-left.
    let sea = CGMutablePath()
    sea.move(to: CGPoint(x: 100, y: 560))
    sea.addCurve(to: CGPoint(x: 330, y: 420), control1: CGPoint(x: 210, y: 560), control2: CGPoint(x: 230, y: 440))
    sea.addCurve(to: CGPoint(x: 470, y: 240), control1: CGPoint(x: 440, y: 400), control2: CGPoint(x: 400, y: 300))
    sea.addCurve(to: CGPoint(x: 700, y: 100), control1: CGPoint(x: 540, y: 180), control2: CGPoint(x: 640, y: 170))
    sea.addLine(to: CGPoint(x: 100, y: 100))
    sea.closeSubpath()
    context.addPath(sea)
    context.setFillColor(color(0x8FBBCB))
    context.fillPath()
    context.addPath(sea)
    context.setStrokeColor(color(0x5D8C9F))
    context.setLineWidth(7)
    context.strokePath()

    // Forest in the top-left.
    context.setFillColor(color(0x8FA86C))
    for (x, y, r) in [(230.0, 800.0, 38.0), (290, 830, 32), (270, 760, 34), (340, 790, 30), (200, 735, 28)] {
        context.fillEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
    }
    // Mountains in the bottom-right.
    context.setFillColor(color(0xA88257))
    for (x, width, height) in [(770.0, 130.0, 120.0), (858, 100, 90), (700, 80, 60)] {
        context.move(to: CGPoint(x: x - width / 2, y: 240))
        context.addLine(to: CGPoint(x: x, y: 240 + height))
        context.addLine(to: CGPoint(x: x + width / 2, y: 240))
        context.closePath()
    }
    context.fillPath()
}

func drawGrid(_ context: CGContext) {
    let step = body.width / 8
    context.setStrokeColor(color(0x5A4020, 0.28))
    context.setLineWidth(3)
    for index in 1..<8 {
        let offset = CGFloat(index) * step
        context.move(to: CGPoint(x: body.minX + offset, y: body.minY))
        context.addLine(to: CGPoint(x: body.minX + offset, y: body.maxY))
        context.move(to: CGPoint(x: body.minX, y: body.minY + offset))
        context.addLine(to: CGPoint(x: body.maxX, y: body.minY + offset))
    }
    context.strokePath()

    // The cut between print tiles: a pale gap with a dashed guide.
    context.setStrokeColor(color(0xFFF8E6))
    context.setLineWidth(16)
    context.move(to: CGPoint(x: body.midX, y: body.minY)); context.addLine(to: CGPoint(x: body.midX, y: body.maxY))
    context.move(to: CGPoint(x: body.minX, y: body.midY)); context.addLine(to: CGPoint(x: body.maxX, y: body.midY))
    context.strokePath()
    context.setStrokeColor(color(0x5A4020, 0.6))
    context.setLineWidth(3)
    context.setLineDash(phase: 0, lengths: [14, 10])
    context.move(to: CGPoint(x: body.midX, y: body.minY)); context.addLine(to: CGPoint(x: body.midX, y: body.maxY))
    context.move(to: CGPoint(x: body.minX, y: body.midY)); context.addLine(to: CGPoint(x: body.maxX, y: body.midY))
    context.strokePath()
    context.setLineDash(phase: 0, lengths: [])
}

/// One compass point: a kite split into a shaded and a lit half.
func drawPoint(_ context: CGContext, angle: CGFloat, length: CGFloat, halfWidth: CGFloat,
               dark: CGColor, light: CGColor) {
    context.saveGState()
    context.rotate(by: angle)
    let tip = CGPoint(x: 0, y: length)
    for (side, fill) in [(-1.0, dark), (1.0, light)] {
        context.move(to: .zero)
        context.addLine(to: tip)
        context.addLine(to: CGPoint(x: side * halfWidth, y: halfWidth))
        context.closePath()
        context.setFillColor(fill)
        context.fillPath()
    }
    context.move(to: .zero)
    context.addLine(to: CGPoint(x: -halfWidth, y: halfWidth))
    context.addLine(to: tip)
    context.addLine(to: CGPoint(x: halfWidth, y: halfWidth))
    context.closePath()
    context.setStrokeColor(color(0x2E2014))
    context.setLineWidth(4)
    context.setLineJoin(.round)
    context.strokePath()
    context.restoreGState()
}

func drawCompass(_ context: CGContext) {
    let center = CGPoint(x: body.midX, y: body.midY)
    context.saveGState()
    context.translateBy(x: center.x, y: center.y)

    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -8), blur: 18, color: color(0x000000, 0.35))
    context.setFillColor(color(0xF7EDD5, 0.92))
    context.fillEllipse(in: CGRect(x: -250, y: -250, width: 500, height: 500))
    context.restoreGState()

    context.setStrokeColor(color(0x2E2014))
    context.setLineWidth(10)
    context.strokeEllipse(in: CGRect(x: -250, y: -250, width: 500, height: 500))
    context.setLineWidth(4)
    context.strokeEllipse(in: CGRect(x: -222, y: -222, width: 444, height: 444))
    for tick in 0..<32 {
        let angle = CGFloat(tick) * .pi / 16
        let inner: CGFloat = tick % 4 == 0 ? 196 : 208
        context.move(to: CGPoint(x: inner * sin(angle), y: inner * cos(angle)))
        context.addLine(to: CGPoint(x: 222 * sin(angle), y: 222 * cos(angle)))
    }
    context.strokePath()

    let ink = color(0x3A2A1A), paper = color(0xF4E9D0)
    for quarter in 0..<4 {
        drawPoint(context, angle: -(CGFloat(quarter) + 0.5) * .pi / 2, length: 185, halfWidth: 42,
                  dark: ink, light: paper)
    }
    for quarter in 1..<4 {
        drawPoint(context, angle: -CGFloat(quarter) * .pi / 2, length: 300, halfWidth: 62, dark: ink, light: paper)
    }
    drawPoint(context, angle: 0, length: 300, halfWidth: 62, dark: color(0x9E2A22), light: color(0xE0645A))

    context.setFillColor(color(0xC9A24A))
    context.fillEllipse(in: CGRect(x: -24, y: -24, width: 48, height: 48))
    context.setStrokeColor(color(0x2E2014))
    context.setLineWidth(4)
    context.strokeEllipse(in: CGRect(x: -24, y: -24, width: 48, height: 48))
    context.restoreGState()

    drawNorthLabel(at: CGPoint(x: center.x, y: center.y + 345))
}

func drawNorthLabel(at point: CGPoint) {
    let font = NSFont(name: "Georgia-Bold", size: 92) ?? NSFont.boldSystemFont(ofSize: 92)
    let label = NSAttributedString(string: "N", attributes: [.font: font, .foregroundColor: NSColor(cgColor: color(0x2E2014))!])
    let bounds = label.size()
    label.draw(at: CGPoint(x: point.x - bounds.width / 2, y: point.y - bounds.height / 2))
}

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write("usage: make-icon.swift <output.png>\n".data(using: .utf8)!)
    exit(1)
}
let context = CGContext(data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
drawBackground(context)
drawTerrain(context)
drawGrid(context)
drawCompass(context)

let output = URL(fileURLWithPath: CommandLine.arguments[1])
let destination = CGImageDestinationCreateWithURL(output as CFURL, "public.png" as CFString, 1, nil)!
CGImageDestinationAddImage(destination, context.makeImage()!, nil)
guard CGImageDestinationFinalize(destination) else { exit(1) }
