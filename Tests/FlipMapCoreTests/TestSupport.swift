import CoreGraphics
import Foundation
@testable import FlipMapCore

/// Shared builders for FlipMapCore tests.
enum TestSupport {
    static let testDataDirectory = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("TestData")

    /// The local sample Flip-Mat PDFs (gitignored; tests using them are skipped when absent).
    static var samplePDFs: [URL] {
        let files = (try? FileManager.default.contentsOfDirectory(at: testDataDirectory, includingPropertiesForKeys: nil))
        return (files ?? []).filter { $0.pathExtension.lowercased() == "pdf" }.sorted { $0.path < $1.path }
    }

    static var hasSamplePDFs: Bool { !samplePDFs.isEmpty }

    /// A white RGB image with black grid lines every `spacing` pixels, over optional noise.
    static func gridImage(width: Int, height: Int, spacing: CGFloat, lineWidth: CGFloat = 1,
                          noise: Bool = false) -> CGImage {
        let context = bitmapContext(width: width, height: height)
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        if noise { drawNoise(context, width: width, height: height) }
        context.setFillColor(CGColor(gray: 0, alpha: 1))
        var position: CGFloat = 0
        while position < CGFloat(max(width, height)) {
            context.fill(CGRect(x: position, y: 0, width: lineWidth, height: CGFloat(height)))
            context.fill(CGRect(x: 0, y: position, width: CGFloat(width), height: lineWidth))
            position += spacing
        }
        return context.makeImage()!
    }

    static func blankImage(width: Int, height: Int) -> CGImage {
        let context = bitmapContext(width: width, height: height)
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()!
    }

    static func bitmapContext(width: Int, height: Int) -> CGContext {
        CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                  space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    }

    /// Random grey blobs, so detection has to find the grid through busy "art".
    static func drawNoise(_ context: CGContext, width: Int, height: Int) {
        var generator = SystemRandomNumberGenerator()
        for _ in 0..<400 {
            let gray = CGFloat.random(in: 0.3...0.9, using: &generator)
            context.setFillColor(CGColor(gray: gray, alpha: 1))
            let size = CGFloat.random(in: 5...60, using: &generator)
            context.fillEllipse(in: CGRect(x: .random(in: 0...CGFloat(width), using: &generator),
                                           y: .random(in: 0...CGFloat(height), using: &generator),
                                           width: size, height: size))
        }
    }

    /// Write a PDF whose pages contain the given images at the given rects (points).
    static func writePDF(pages: [[(CGImage, CGRect)]], pageSize: CGSize = CGSize(width: 612, height: 792)) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).pdf")
        var mediaBox = CGRect(origin: .zero, size: pageSize)
        let context = CGContext(url as CFURL, mediaBox: &mediaBox, nil)!
        for placements in pages {
            context.beginPDFPage(nil)
            for (image, rect) in placements { context.draw(image, in: rect) }
            context.endPDFPage()
        }
        context.closePDF()
        return url
    }

    static let letterPage = PageGeometry(
        paperSize: CGSize(width: 612, height: 792),
        imageableRect: CGRect(x: 18, y: 18, width: 576, height: 756)  // 8 × 10.5 in
    )
}
