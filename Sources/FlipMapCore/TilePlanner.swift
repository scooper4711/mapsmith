import CoreGraphics

/// How a map is cut into printer pages.
public struct TilePlan: Equatable, Sendable {
    /// Whether the map is turned 90° clockwise before tiling, to use fewer sheets.
    public let rotated: Bool
    public let columns: Int
    public let rows: Int
    /// Map pixels per inch of print.
    public let pixelsPerInch: CGFloat
    /// Size of the (possibly rotated) map in pixels.
    public let mapSize: CGSize
    /// One rect per page in (possibly rotated) map pixels, row by row from the top-left.
    /// Edge tiles are narrower when the map runs out; thin edge strips are trimmed.
    public let tiles: [CGRect]

    public var sheetCount: Int { tiles.count }
}

/// Settings that shape a tile plan.
public struct TileSettings: Equatable, Sendable {
    public var page: PageGeometry
    /// Trailing rows/columns holding less than this much map are trimmed, not printed.
    public var minimumSliverInches: CGFloat

    public init(page: PageGeometry, minimumSliverInches: CGFloat = 0.5) {
        self.page = page
        self.minimumSliverInches = minimumSliverInches
    }
}

/// Plans how to split a map across printer pages at true scale.
public enum TilePlanner {
    /// Plan tiles for a map of `mapSize` pixels printed at `pixelsPerInch`.
    ///
    /// Tries the map both upright and rotated 90° and keeps whichever needs fewer
    /// sheets (upright on a tie).
    public static func plan(mapSize: CGSize, pixelsPerInch: CGFloat, settings: TileSettings) -> TilePlan {
        let upright = plan(mapSize: mapSize, pixelsPerInch: pixelsPerInch, settings: settings, rotated: false)
        let turned = plan(mapSize: mapSize, pixelsPerInch: pixelsPerInch, settings: settings, rotated: true)
        return turned.sheetCount < upright.sheetCount ? turned : upright
    }

    static func plan(mapSize: CGSize, pixelsPerInch: CGFloat, settings: TileSettings, rotated: Bool) -> TilePlan {
        let size = rotated ? CGSize(width: mapSize.height, height: mapSize.width) : mapSize
        let tileSize = CGSize(
            width: settings.page.imageableSizeInches.width * pixelsPerInch,
            height: settings.page.imageableSizeInches.height * pixelsPerInch
        )
        let sliver = settings.minimumSliverInches * pixelsPerInch
        let xSpans = spans(length: size.width, tile: tileSize.width, minimumSliver: sliver)
        let ySpans = spans(length: size.height, tile: tileSize.height, minimumSliver: sliver)

        let tiles = ySpans.flatMap { y in
            xSpans.map { x in CGRect(x: x.lowerBound, y: y.lowerBound, width: x.upperBound - x.lowerBound,
                                     height: y.upperBound - y.lowerBound) }
        }
        return TilePlan(rotated: rotated, columns: xSpans.count, rows: ySpans.count,
                        pixelsPerInch: pixelsPerInch, mapSize: size, tiles: tiles)
    }

    /// Split `0..<length` into tile-sized spans, trimming a thin remainder equally from both ends.
    static func spans(length: CGFloat, tile: CGFloat, minimumSliver: CGFloat) -> [Range<CGFloat>] {
        guard length > 0, tile > 0 else { return [] }
        let fullTiles = Int((length / tile).rounded(.down))
        let remainder = length - CGFloat(fullTiles) * tile
        let trimsRemainder = fullTiles > 0 && remainder < minimumSliver
        let count = trimsRemainder || remainder < 0.5 ? max(fullTiles, 1) : fullTiles + 1
        let start = trimsRemainder ? (remainder / 2).rounded(.down) : 0
        let end = trimsRemainder ? start + CGFloat(fullTiles) * tile : length

        return (0..<count).map { index in
            let lower = (start + CGFloat(index) * tile).rounded()
            let upper = min((start + CGFloat(index + 1) * tile).rounded(), end.rounded())
            return lower..<upper
        }
    }
}
