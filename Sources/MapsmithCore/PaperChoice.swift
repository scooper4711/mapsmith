import CoreGraphics

/// A paper size the user picks where there is no Page Setup (the iPad), with the printer's unprintable border.
public enum PaperChoice: String, CaseIterable, Identifiable, Sendable {
    case letter, legal, a4, a3, tabloid

    /// What fits most AirPrint printers: their unprintable border is 1/4 in or less.
    public static let defaultMarginInches: CGFloat = 0.25
    /// The margin is kept between nothing and a quarter of the narrowest paper's width.
    public static let marginRange: ClosedRange<CGFloat> = 0...2

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .letter: "US Letter"
        case .legal: "US Legal"
        case .a4: "A4"
        case .a3: "A3"
        case .tabloid: "Tabloid"
        }
    }

    /// The paper's size in points, portrait.
    public var size: CGSize {
        switch self {
        case .letter: CGSize(width: 612, height: 792)
        case .legal: CGSize(width: 612, height: 1008)
        case .a4: CGSize(width: 595.28, height: 841.89)
        case .a3: CGSize(width: 841.89, height: 1190.55)
        case .tabloid: CGSize(width: 792, height: 1224)
        }
    }

    /// The printable page: the paper with `marginInches` left blank on every side, the margin clamped to
    /// `marginRange`.
    public func geometry(marginInches: CGFloat) -> PageGeometry {
        let clamped = min(max(marginInches, Self.marginRange.lowerBound), Self.marginRange.upperBound)
        let margin = clamped * pointsPerInch
        let paper = CGRect(origin: .zero, size: size)
        return PageGeometry(paperSize: size, imageableRect: paper.insetBy(dx: margin, dy: margin))
    }

    /// The paper the user's region most likely uses: US Letter in the US and Canada and the other Letter
    /// countries, A4 elsewhere.
    public static func regionalDefault(regionCode: String?) -> PaperChoice {
        let letterRegions: Set = ["US", "CA", "MX", "PH", "CL", "CO", "VE", "GT", "CR", "PA", "DO", "SV", "NI", "PR"]
        return regionCode.map(letterRegions.contains) == true ? .letter : .a4
    }
}
