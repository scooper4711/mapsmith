import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Why tiles could not be exported.
public enum TileExportError: Error, Equatable, CustomStringConvertible {
    case imageProcessingFailed(String)

    public var description: String {
        switch self {
        case .imageProcessingFailed(let step): return "Tile export failed while \(step)"
        }
    }
}

/// Renders a tile plan into a print-ready PDF: one page per tile, at true scale.
public enum TileExporter {
    static let jpegQuality = 0.92

    /// A PDF with one `page`-sized page per tile, each tile's top-left at the printable area's top-left.
    public static func pdfData(map: CGImage, plan: TilePlan, page: PageGeometry) throws -> Data {
        let oriented = plan.rotated ? try rotatedClockwise(map) : map
        let data = NSMutableData()
        var mediaBox = CGRect(origin: .zero, size: page.paperSize)
        guard let consumer = CGDataConsumer(data: data as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil)
        else { throw TileExportError.imageProcessingFailed("creating the PDF") }

        for tile in plan.tiles {
            let image = try jpegTile(oriented, rect: tile)
            let size = CGSize(width: tile.width / plan.pixelsPerInch * pointsPerInch,
                              height: tile.height / plan.pixelsPerInch * pointsPerInch)
            let origin = CGPoint(x: page.imageableRect.minX, y: page.imageableRect.maxY - size.height)
            context.beginPDFPage(nil)
            context.draw(image, in: CGRect(origin: origin, size: size))
            context.endPDFPage()
        }
        context.closePDF()
        return data as Data
    }

    /// `image` turned 90° clockwise, matching `TilePlan.rotated`.
    public static func rotatedClockwise(_ image: CGImage) throws -> CGImage {
        guard let context = CGContext(data: nil, width: image.height, height: image.width, bitsPerComponent: 8,
                                      bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                      bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
        else { throw TileExportError.imageProcessingFailed("rotating the map") }
        context.translateBy(x: 0, y: CGFloat(image.width))
        context.rotate(by: -.pi / 2)
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        guard let rotated = context.makeImage() else { throw TileExportError.imageProcessingFailed("rotating the map") }
        return rotated
    }

    /// The tile cropped out and re-encoded as JPEG, so the PDF embeds compressed image data.
    static func jpegTile(_ image: CGImage, rect: CGRect) throws -> CGImage {
        guard let crop = image.cropping(to: rect.integral) else {
            throw TileExportError.imageProcessingFailed("cropping a tile")
        }
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil)
        else { throw TileExportError.imageProcessingFailed("encoding a tile") }
        CGImageDestinationAddImage(destination, crop,
                                   [kCGImageDestinationLossyCompressionQuality: jpegQuality] as CFDictionary)
        guard CGImageDestinationFinalize(destination), let provider = CGDataProvider(data: data),
              let jpeg = CGImage(jpegDataProviderSource: provider, decode: nil, shouldInterpolate: true,
                                 intent: .defaultIntent)
        else { throw TileExportError.imageProcessingFailed("encoding a tile") }
        return jpeg
    }
}
