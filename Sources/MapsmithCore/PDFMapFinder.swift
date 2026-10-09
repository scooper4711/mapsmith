import CoreGraphics
import Foundation

/// A map found in a PDF: an area of one page covered by a large raster image.
public struct PDFMapRegion: Equatable, Sendable {
    /// Zero-based page index.
    public let pageIndex: Int
    /// Area of the page in PDF user-space points.
    public let rect: CGRect
    /// Pixel dimensions of the image drawn there (zero for whole-page fallbacks).
    public let pixelSize: CGSize

    /// Resolution at which the image is placed on the page, in pixels per inch.
    public var nativeDPI: CGFloat {
        guard pixelSize != .zero else { return 0 }
        let diagonalPixels = hypot(pixelSize.width, pixelSize.height)
        return diagonalPixels / (hypot(rect.width, rect.height) / pointsPerInch)
    }
}

/// Locates the large raster images in a PDF by scanning each page's content stream.
public enum PDFMapFinder {
    /// Images covering less than this fraction of the page are decorations, not maps.
    static let minimumPageFraction: CGFloat = 0.1
    static let minimumPixels: CGFloat = 300
    /// Images overlapping by this fraction of the smaller one are treated as one map.
    static let duplicateOverlap: CGFloat = 0.9

    /// All maps in `document`. When no page holds a large image, every page is returned whole.
    public static func maps(in document: CGPDFDocument) -> [PDFMapRegion] {
        let pages = (0..<document.numberOfPages).compactMap { document.page(at: $0 + 1) }
        let found = pages.enumerated().flatMap { index, page in maps(on: page, pageIndex: index) }
        guard found.isEmpty else { return found }
        return pages.enumerated().map { index, page in
            PDFMapRegion(pageIndex: index, rect: page.getBoxRect(.cropBox), pixelSize: .zero)
        }
    }

    static func maps(on page: CGPDFPage, pageIndex: Int) -> [PDFMapRegion] {
        let pageRect = page.getBoxRect(.cropBox)
        let large = ImagePlacementScanner.placements(on: page)
            .map { PDFMapRegion(pageIndex: pageIndex, rect: $0.rect.intersection(pageRect), pixelSize: $0.pixelSize) }
            .filter { isLarge($0, pageRect: pageRect) }
        return mergingDuplicates(large)
    }

    static func isLarge(_ region: PDFMapRegion, pageRect: CGRect) -> Bool {
        guard !region.rect.isNull else { return false }
        let fraction = (region.rect.width * region.rect.height) / (pageRect.width * pageRect.height)
        return fraction >= minimumPageFraction && max(region.pixelSize.width, region.pixelSize.height) >= minimumPixels
    }

    /// Collapse images stacked on the same area (e.g. a colour layer plus overlay) into one map.
    static func mergingDuplicates(_ regions: [PDFMapRegion]) -> [PDFMapRegion] {
        var merged: [PDFMapRegion] = []
        for region in regions {
            if let index = merged.firstIndex(where: { overlapFraction($0.rect, region.rect) >= duplicateOverlap }) {
                let existing = merged[index]
                let largerPixels = region.pixelSize.width * region.pixelSize.height >
                    existing.pixelSize.width * existing.pixelSize.height ? region.pixelSize : existing.pixelSize
                merged[index] = PDFMapRegion(pageIndex: region.pageIndex, rect: existing.rect.union(region.rect),
                                             pixelSize: largerPixels)
            } else {
                merged.append(region)
            }
        }
        return merged
    }

    static func overlapFraction(_ first: CGRect, _ second: CGRect) -> CGFloat {
        let overlap = first.intersection(second)
        guard !overlap.isNull else { return 0 }
        let smaller = min(first.width * first.height, second.width * second.height)
        return smaller > 0 ? overlap.width * overlap.height / smaller : 0
    }
}

/// Where an image XObject is drawn on a page.
struct ImagePlacement {
    let rect: CGRect
    let pixelSize: CGSize
}

/// Walks a page's content stream tracking the transformation matrix, recording image draws.
final class ImagePlacementScanner {
    private static let maximumFormDepth = 8

    private var transform = CGAffineTransform.identity
    private var savedTransforms: [CGAffineTransform] = []
    private var formDepth = 0
    private var placements: [ImagePlacement] = []
    private let operators: CGPDFOperatorTableRef

    static func placements(on page: CGPDFPage) -> [ImagePlacement] {
        let scanner = ImagePlacementScanner()
        let stream = CGPDFContentStreamCreateWithPage(page)
        scanner.scan(stream)
        CGPDFContentStreamRelease(stream)
        return scanner.placements
    }

    private init() {
        operators = CGPDFOperatorTableCreate()!
        CGPDFOperatorTableSetCallback(operators, "q") { _, info in
            ImagePlacementScanner.from(info).saveState()
        }
        CGPDFOperatorTableSetCallback(operators, "Q") { _, info in
            ImagePlacementScanner.from(info).restoreState()
        }
        CGPDFOperatorTableSetCallback(operators, "cm") { scanner, info in
            ImagePlacementScanner.from(info).concatenateMatrix(scanner)
        }
        CGPDFOperatorTableSetCallback(operators, "Do") { scanner, info in
            ImagePlacementScanner.from(info).drawXObject(scanner)
        }
    }

    deinit { CGPDFOperatorTableRelease(operators) }

    private static func from(_ info: UnsafeMutableRawPointer?) -> ImagePlacementScanner {
        Unmanaged<ImagePlacementScanner>.fromOpaque(info!).takeUnretainedValue()
    }

    private func scan(_ stream: CGPDFContentStreamRef) {
        let scanner = CGPDFScannerCreate(stream, operators, Unmanaged.passUnretained(self).toOpaque())
        CGPDFScannerScan(scanner)
        CGPDFScannerRelease(scanner)
    }

    private func saveState() { savedTransforms.append(transform) }

    private func restoreState() { transform = savedTransforms.popLast() ?? transform }

    private func concatenateMatrix(_ scanner: CGPDFScannerRef) {
        var values = [CGPDFReal](repeating: 0, count: 6)
        for index in stride(from: 5, through: 0, by: -1) {
            guard CGPDFScannerPopNumber(scanner, &values[index]) else { return }
        }
        let matrix = CGAffineTransform(a: values[0], b: values[1], c: values[2], d: values[3],
                                       tx: values[4], ty: values[5])
        transform = matrix.concatenating(transform)
    }

    private func drawXObject(_ scanner: CGPDFScannerRef) {
        var namePointer: UnsafePointer<CChar>?
        guard CGPDFScannerPopName(scanner, &namePointer), let namePointer,
              let stream = CGPDFScannerGetContentStream(scanner) as CGPDFContentStreamRef?,
              let object = CGPDFContentStreamGetResource(stream, "XObject", namePointer)
        else { return }

        var xObject: CGPDFStreamRef?
        guard CGPDFObjectGetValue(object, .stream, &xObject), let xObject,
              let dictionary = CGPDFStreamGetDictionary(xObject)
        else { return }

        switch Self.name(in: dictionary, key: "Subtype") {
        case "Image": recordImage(dictionary)
        case "Form": scanForm(xObject, dictionary: dictionary, parent: stream)
        default: break
        }
    }

    private func recordImage(_ dictionary: CGPDFDictionaryRef) {
        var width: CGPDFInteger = 0, height: CGPDFInteger = 0
        guard CGPDFDictionaryGetInteger(dictionary, "Width", &width),
              CGPDFDictionaryGetInteger(dictionary, "Height", &height)
        else { return }
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1).applying(transform)
        placements.append(ImagePlacement(rect: rect, pixelSize: CGSize(width: Int(width), height: Int(height))))
    }

    private func scanForm(_ stream: CGPDFStreamRef, dictionary: CGPDFDictionaryRef, parent: CGPDFContentStreamRef) {
        guard formDepth < Self.maximumFormDepth else { return }
        var resources: CGPDFDictionaryRef?
        _ = CGPDFDictionaryGetDictionary(dictionary, "Resources", &resources)

        let saved = transform
        transform = Self.formMatrix(dictionary).concatenating(transform)
        formDepth += 1
        let formStream = CGPDFContentStreamCreateWithStream(stream, resources ?? dictionary, parent)
        scan(formStream)
        CGPDFContentStreamRelease(formStream)
        formDepth -= 1
        transform = saved
    }

    private static func formMatrix(_ dictionary: CGPDFDictionaryRef) -> CGAffineTransform {
        var array: CGPDFArrayRef?
        guard CGPDFDictionaryGetArray(dictionary, "Matrix", &array), let array, CGPDFArrayGetCount(array) == 6
        else { return .identity }
        var values = [CGPDFReal](repeating: 0, count: 6)
        for index in 0..<6 { _ = CGPDFArrayGetNumber(array, index, &values[index]) }
        return CGAffineTransform(a: values[0], b: values[1], c: values[2], d: values[3], tx: values[4], ty: values[5])
    }

    private static func name(in dictionary: CGPDFDictionaryRef, key: String) -> String? {
        var pointer: UnsafePointer<CChar>?
        guard CGPDFDictionaryGetName(dictionary, key, &pointer), let pointer else { return nil }
        return String(cString: pointer)
    }
}
