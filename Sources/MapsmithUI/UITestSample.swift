#if DEBUG && os(iOS)
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// The maps the UI tests open, since the sample maps are copyrighted and the tests can't hand the app a file:
/// a gridded image (launch argument `-UITestSample`) or a PDF of two gridded pages (`-UITestSamplePDF`).
enum UITestSample {
    static let argument = "-UITestSample"
    static let pdfArgument = "-UITestSamplePDF"
    static let squarePixels = 100

    static func urlIfRequested() -> URL? {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains(pdfArgument) { return twoPagePDF() }
        guard arguments.contains(argument) else { return nil }
        let url = FileManager.default.temporaryDirectory.appending(path: "UI Test Map.png")
        guard let image = drawGrid(columns: 30, rows: 20), write(image, to: url) else { return nil }
        return url
    }

    /// Two pages with the gridded image on each, which the app lists as two maps.
    private static func twoPagePDF() -> URL? {
        let url = FileManager.default.temporaryDirectory.appending(path: "UI Test Maps.pdf")
        var page = CGRect(x: 0, y: 0, width: 720, height: 480)
        guard let image = drawGrid(columns: 30, rows: 20),
              let context = CGContext(url as CFURL, mediaBox: &page, nil) else { return nil }
        for _ in 1...2 {
            context.beginPDFPage(nil)
            context.draw(image, in: page)
            context.endPDFPage()
        }
        context.closePDF()
        return url
    }

    private static func drawGrid(columns: Int, rows: Int) -> CGImage? {
        let width = columns * squarePixels, height = rows * squarePixels
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                                      space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
        else { return nil }
        context.setFillColor(CGColor(srgbRed: 0.93, green: 0.88, blue: 0.76, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.setStrokeColor(CGColor(gray: 0.2, alpha: 1))
        context.setLineWidth(3)
        for column in 0...columns {
            context.move(to: CGPoint(x: column * squarePixels, y: 0))
            context.addLine(to: CGPoint(x: column * squarePixels, y: height))
        }
        for row in 0...rows {
            context.move(to: CGPoint(x: 0, y: row * squarePixels))
            context.addLine(to: CGPoint(x: width, y: row * squarePixels))
        }
        context.strokePath()
        return context.makeImage()
    }

    private static func write(_ image: CGImage, to url: URL) -> Bool {
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1,
                                                                nil) else { return false }
        CGImageDestinationAddImage(destination, image, nil)
        return CGImageDestinationFinalize(destination)
    }
}
#endif
