import CoreGraphics

/// The print scale as the user enters it: pixels per 1-inch square, or how many squares the map spans.
public enum ScaleEntry: Equatable, Sendable {
    case pixelsPerSquare(Double)
    case squaresAcross(Double)
    case squaresDown(Double)

    /// Map pixels per inch for a map of `mapSize` pixels; nil unless that comes to a positive number.
    public func pixelsPerInch(mapSize: CGSize) -> Double? {
        let pixels = switch self {
        case .pixelsPerSquare(let pixels): pixels
        case .squaresAcross(let count): mapSize.width / count
        case .squaresDown(let count): mapSize.height / count
        }
        return pixels > 0 && pixels.isFinite ? pixels : nil
    }

    /// How many 1-inch squares a map of `mapSize` pixels spans at the scale.
    public static func squares(mapSize: CGSize, pixelsPerInch: Double) -> CGSize {
        guard pixelsPerInch > 0 else { return .zero }
        return CGSize(width: mapSize.width / pixelsPerInch, height: mapSize.height / pixelsPerInch)
    }
}
