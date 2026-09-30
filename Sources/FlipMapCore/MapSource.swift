import CoreGraphics
import Foundation
import ImageIO

/// Why a map could not be loaded or rendered.
public enum MapLoadError: Error, Equatable, CustomStringConvertible {
    case unreadableFile(String)
    case renderFailed(String)

    public var description: String {
        switch self {
        case .unreadableFile(let name): return "Cannot open \(name)"
        case .renderFailed(let name): return "Cannot render \(name)"
        }
    }
}

/// Where a map's pixels come from.
public enum MapSource: Equatable, Sendable {
    case imageFile(URL)
    case pdfRegion(URL, PDFMapRegion)
}

/// A map at full resolution, with the scale to fall back on if grid detection fails.
public struct LoadedMap: @unchecked Sendable {
    public let image: CGImage
    /// Pixels per inch implied by the file itself (PDF render resolution or image DPI metadata).
    public let fallbackPixelsPerInch: CGFloat?
    public let fallbackDescription: String
}

/// One selectable map in an opened file.
public struct MapItem: Identifiable, Equatable, Sendable {
    public let id = UUID()
    public let title: String
    public let source: MapSource

    /// Every map in the file at `url`: each large image of a PDF, or the image itself.
    public static func items(in url: URL) throws -> [MapItem] {
        guard url.pathExtension.lowercased() == "pdf" else {
            return [MapItem(title: url.deletingPathExtension().lastPathComponent, source: .imageFile(url))]
        }
        guard let document = CGPDFDocument(url as CFURL) else {
            throw MapLoadError.unreadableFile(url.lastPathComponent)
        }
        let regions = PDFMapFinder.maps(in: document)
        let perPage = Dictionary(grouping: regions, by: \.pageIndex).mapValues(\.count)
        var seen: [Int: Int] = [:]
        return regions.map { region in
            seen[region.pageIndex, default: 0] += 1
            let suffix = perPage[region.pageIndex, default: 1] > 1 ? " – map \(seen[region.pageIndex]!)" : ""
            return MapItem(title: "Page \(region.pageIndex + 1)\(suffix)", source: .pdfRegion(url, region))
        }
    }

    public static func == (lhs: MapItem, rhs: MapItem) -> Bool { lhs.id == rhs.id }
}

/// Loads map pixels and thumbnails.
public enum MapLoader {
    /// PDF maps render at their images' native resolution, within these bounds.
    static let pdfDPIRange: ClosedRange<CGFloat> = 300...600
    static let maximumRenderPixels: CGFloat = 120_000_000

    public static func load(_ source: MapSource) throws -> LoadedMap {
        switch source {
        case .imageFile(let url): return try loadImage(url)
        case let .pdfRegion(url, region): return try loadPDFRegion(url, region: region)
        }
    }

    public static func thumbnail(_ source: MapSource, maximumSize: CGFloat) throws -> CGImage {
        switch source {
        case .imageFile(let url):
            let options = [kCGImageSourceCreateThumbnailFromImageAlways: true,
                           kCGImageSourceCreateThumbnailWithTransform: true,
                           kCGImageSourceThumbnailMaxPixelSize: maximumSize] as CFDictionary
            guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
                  let image = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options)
            else { throw MapLoadError.unreadableFile(url.lastPathComponent) }
            return image
        case let .pdfRegion(url, region):
            let dpi = maximumSize / max(region.rect.width, region.rect.height) * pointsPerInch
            return try render(url, region: region, dpi: dpi)
        }
    }

    static func loadImage(_ url: URL) throws -> LoadedMap {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
        else { throw MapLoadError.unreadableFile(url.lastPathComponent) }

        let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any]
        // ImageIO reports 72 DPI for files with no resolution set, so treat 72 as unknown.
        let dpi = (properties?[kCGImagePropertyDPIWidth] as? NSNumber).map { CGFloat($0.doubleValue) }
        let usable = dpi.flatMap { $0 > 0 && $0 != 72 ? $0 : nil }
        return LoadedMap(image: image, fallbackPixelsPerInch: usable,
                         fallbackDescription: usable.map { "image metadata (\(Int($0)) DPI)" } ?? "none")
    }

    static func loadPDFRegion(_ url: URL, region: PDFMapRegion) throws -> LoadedMap {
        let dpi = renderDPI(for: region)
        let image = try render(url, region: region, dpi: dpi)
        return LoadedMap(image: image, fallbackPixelsPerInch: dpi,
                         fallbackDescription: "PDF page scale (\(Int(dpi.rounded())) DPI)")
    }

    static func renderDPI(for region: PDFMapRegion) -> CGFloat {
        let native = region.nativeDPI > 0 ? region.nativeDPI : pdfDPIRange.lowerBound
        let clamped = min(max(native, pdfDPIRange.lowerBound), pdfDPIRange.upperBound)
        let areaSquareInches = region.rect.width * region.rect.height / (pointsPerInch * pointsPerInch)
        return min(clamped, (maximumRenderPixels / areaSquareInches).squareRoot()).rounded()
    }

    /// Render `region` of its PDF page to a bitmap at `dpi`.
    static func render(_ url: URL, region: PDFMapRegion, dpi: CGFloat) throws -> CGImage {
        let scale = dpi / pointsPerInch
        let width = Int((region.rect.width * scale).rounded()), height = Int((region.rect.height * scale).rounded())
        guard let document = CGPDFDocument(url as CFURL), let page = document.page(at: region.pageIndex + 1),
              width > 0, height > 0,
              let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                                      space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                      bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
        else { throw MapLoadError.renderFailed(url.lastPathComponent) }

        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.interpolationQuality = .high
        context.scaleBy(x: scale, y: scale)
        context.translateBy(x: -region.rect.minX, y: -region.rect.minY)
        context.clip(to: region.rect)
        context.drawPDFPage(page)

        guard let image = context.makeImage() else { throw MapLoadError.renderFailed(url.lastPathComponent) }
        return image
    }
}
