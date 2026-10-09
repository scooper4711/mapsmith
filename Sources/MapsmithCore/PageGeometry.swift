import CoreGraphics

/// Points per inch in PDF and AppKit page coordinates.
public let pointsPerInch: CGFloat = 72

/// The physical page and the part of it the printer can mark, in points.
///
/// `imageableRect` uses PDF page coordinates: origin at the bottom-left of the paper.
public struct PageGeometry: Equatable, Sendable {
    public var paperSize: CGSize
    public var imageableRect: CGRect

    public init(paperSize: CGSize, imageableRect: CGRect) {
        self.paperSize = paperSize
        self.imageableRect = imageableRect
    }

    /// A4 with a uniform 4.2 mm margin — a safe default until the user picks a printer.
    public static let a4Default: PageGeometry = {
        let paper = CGSize(width: 595.28, height: 841.89)
        let margin = 4.2 / 25.4 * pointsPerInch
        return PageGeometry(
            paperSize: paper,
            imageableRect: CGRect(origin: .zero, size: paper).insetBy(dx: margin, dy: margin)
        )
    }()

    /// Printable width and height in inches.
    public var imageableSizeInches: CGSize {
        CGSize(width: imageableRect.width / pointsPerInch, height: imageableRect.height / pointsPerInch)
    }
}
