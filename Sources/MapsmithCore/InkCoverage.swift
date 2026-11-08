import CoreGraphics

/// The inks a map is printed with.
public enum InkColor: String, Codable, CaseIterable, Sendable {
    case cyan, magenta, yellow, black
    /// A cartridge that isn't charged for maps, such as a printer's second black.
    case unused
}

/// How much of a sheet each ink covers, in page-equivalents: 1.0 is one sheet of the paper covered
/// completely by that ink. Coverages of several pages add up.
public struct InkCoverage: Equatable, Sendable {
    public var cyan: Double
    public var magenta: Double
    public var yellow: Double
    public var black: Double

    public init(cyan: Double = 0, magenta: Double = 0, yellow: Double = 0, black: Double = 0) {
        self.cyan = cyan
        self.magenta = magenta
        self.yellow = yellow
        self.black = black
    }

    public static let zero = InkCoverage()

    public subscript(ink: InkColor) -> Double {
        switch ink {
        case .cyan: cyan
        case .magenta: magenta
        case .yellow: yellow
        case .black: black
        case .unused: 0
        }
    }

    public static func + (lhs: InkCoverage, rhs: InkCoverage) -> InkCoverage {
        InkCoverage(cyan: lhs.cyan + rhs.cyan, magenta: lhs.magenta + rhs.magenta,
                    yellow: lhs.yellow + rhs.yellow, black: lhs.black + rhs.black)
    }

    func scaled(by factor: Double) -> InkCoverage {
        InkCoverage(cyan: cyan * factor, magenta: magenta * factor, yellow: yellow * factor, black: black * factor)
    }
}

/// Works out the ink each printed tile needs by separating it into cyan, magenta, yellow and black.
public enum InkCoverageEstimator {
    /// Resolution the tiles are separated at; plenty for an average.
    static let pixelsPerInch: CGFloat = 36

    /// One coverage per tile of `plan`, as `TileExporter` prints them on `page`.
    public static func coverage(map: CGImage, plan: TilePlan, page: PageGeometry) throws -> [InkCoverage] {
        let oriented = plan.rotated ? try TileExporter.rotatedClockwise(map) : map
        let paperArea = Double(page.paperSize.width * page.paperSize.height)
        guard paperArea > 0 else { return plan.tiles.map { _ in .zero } }
        return try plan.tiles.map { tile in
            guard let crop = oriented.cropping(to: tile.integral) else {
                throw TileExportError.imageProcessingFailed("cropping a tile for the ink estimate")
            }
            let printedSize = CGSize(width: tile.width / plan.pixelsPerInch * pointsPerInch,
                                     height: tile.height / plan.pixelsPerInch * pointsPerInch)
            let share = Double(printedSize.width * printedSize.height) / paperArea
            return try averageCoverage(of: crop, printedSize: printedSize).scaled(by: share)
        }
    }

    /// The average of each CMYK channel over the image, drawn at `pixelsPerInch` for its printed size.
    static func averageCoverage(of image: CGImage, printedSize: CGSize) throws -> InkCoverage {
        let width = max(1, Int((printedSize.width / pointsPerInch * pixelsPerInch).rounded()))
        let height = max(1, Int((printedSize.height / pointsPerInch * pixelsPerInch).rounded()))
        guard let space = CGColorSpace(name: CGColorSpace.genericCMYK),
              let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                                      bytesPerRow: width * 4, space: space,
                                      bitmapInfo: CGImageAlphaInfo.none.rawValue)
        else { throw TileExportError.imageProcessingFailed("separating a tile into inks") }
        context.interpolationQuality = .medium
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let data = context.data else {
            throw TileExportError.imageProcessingFailed("separating a tile into inks")
        }
        return channelAverages(data.bindMemory(to: UInt8.self, capacity: width * height * 4),
                               pixelCount: width * height)
    }

    private static func channelAverages(_ bytes: UnsafePointer<UInt8>, pixelCount: Int) -> InkCoverage {
        var sums = [Int](repeating: 0, count: 4)
        for pixel in 0..<pixelCount {
            for channel in 0..<4 { sums[channel] += Int(bytes[pixel * 4 + channel]) }
        }
        let scale = 1 / (255 * Double(pixelCount))
        return InkCoverage(cyan: Double(sums[0]) * scale, magenta: Double(sums[1]) * scale,
                           yellow: Double(sums[2]) * scale, black: Double(sums[3]) * scale)
    }
}
