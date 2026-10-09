import CoreGraphics
import Foundation

/// Why grid detection could not produce a spacing.
public enum GridDetectionError: Error, Equatable, CustomStringConvertible {
    case imageTooSmall
    case noGridFound(axis: String)
    case axesDisagree(horizontal: CGFloat, vertical: CGFloat)

    public var description: String {
        switch self {
        case .imageTooSmall:
            return "Grid detection failed: image too small"
        case .noGridFound(let axis):
            return "Grid detection failed: no regular \(axis) grid lines found"
        case let .axesDisagree(horizontal, vertical):
            return String(format: "Grid detection failed: column spacing %.1f px ≠ row spacing %.1f px",
                          horizontal, vertical)
        }
    }
}

/// Finds the grid-square spacing of a battle map.
///
/// Sums edge strength down every column and along every row, removes the slowly
/// varying background, and finds the repeat distance of the resulting profiles by
/// autocorrelation. Grid lines run the full length of the map, so they dominate
/// the profiles even when the art is busy.
public enum GridDetector {
    /// Longest side the image is reduced to before analysis.
    static let analysisSize = 2000
    /// Smallest spacing considered, in analysis pixels.
    static let minimumSpacing = 8
    /// Autocorrelation peak (relative to lag 0) needed to accept a grid.
    static let minimumStrength = 0.1
    /// Maximum relative difference between column and row spacing.
    static let axisTolerance = 0.02

    /// Grid spacing in pixels of `image`.
    public static func spacing(in image: CGImage) throws -> CGFloat {
        let scale = min(1, CGFloat(analysisSize) / CGFloat(max(image.width, image.height)))
        let gray = try GrayImage(image: image, scale: scale)

        let columnSpacing = try period(of: gray.columnEdgeProfile(), axis: "vertical")
        let rowSpacing = try period(of: gray.rowEdgeProfile(), axis: "horizontal")
        guard abs(columnSpacing - rowSpacing) / max(columnSpacing, rowSpacing) <= axisTolerance else {
            throw GridDetectionError.axesDisagree(horizontal: columnSpacing / scale, vertical: rowSpacing / scale)
        }
        return (columnSpacing + rowSpacing) / 2 / scale
    }

    /// Dominant repeat distance of `profile`, refined to sub-pixel precision.
    static func period(of profile: [Double], axis: String) throws -> CGFloat {
        let signal = highPass(profile, radius: 8)
        let correlation = autocorrelation(signal, maximumLag: signal.count / 2)
        let searchLimit = signal.count / 4  // require at least four repeats
        guard searchLimit > minimumSpacing else { throw GridDetectionError.imageTooSmall }

        let peaks = localMaxima(correlation, in: minimumSpacing...searchLimit)
        guard let strongest = peaks.map({ correlation[$0] }).max(), strongest >= minimumStrength,
              let fundamental = peaks.first(where: { correlation[$0] >= strongest * 0.85 })
        else { throw GridDetectionError.noGridFound(axis: axis) }

        return refine(fundamental: fundamental, correlation: correlation)
    }

    /// Improve precision by locating the farthest clear multiple of the fundamental lag.
    static func refine(fundamental: Int, correlation: [Double]) -> CGFloat {
        let multiple = max(1, (correlation.count - 1 - fundamental / 2) / fundamental)
        let expected = multiple * fundamental
        let window = max(1, fundamental / 4)
        let range = max(1, expected - window)...min(correlation.count - 2, expected + window)
        let peak = range.max { correlation[$0] < correlation[$1] } ?? expected
        return (CGFloat(peak) + parabolicOffset(correlation, at: peak)) / CGFloat(multiple)
    }

    static func highPass(_ values: [Double], radius: Int) -> [Double] {
        var prefix = [0.0]
        prefix.reserveCapacity(values.count + 1)
        for value in values { prefix.append(prefix[prefix.count - 1] + value) }
        return values.indices.map { index in
            let low = max(0, index - radius), high = min(values.count, index + radius + 1)
            return values[index] - (prefix[high] - prefix[low]) / Double(high - low)
        }
    }

    static func autocorrelation(_ values: [Double], maximumLag: Int) -> [Double] {
        let zeroLag = values.reduce(0) { $0 + $1 * $1 }
        guard zeroLag > 0 else { return [Double](repeating: 0, count: maximumLag + 1) }
        return (0...maximumLag).map { lag in
            var sum = 0.0
            for index in 0..<(values.count - lag) { sum += values[index] * values[index + lag] }
            return sum / zeroLag
        }
    }

    static func localMaxima(_ values: [Double], in range: ClosedRange<Int>) -> [Int] {
        range.filter { $0 > 0 && $0 < values.count - 1 && values[$0] > values[$0 - 1] && values[$0] >= values[$0 + 1] }
    }

    static func parabolicOffset(_ values: [Double], at index: Int) -> CGFloat {
        guard index > 0, index < values.count - 1 else { return 0 }
        let left = values[index - 1], center = values[index], right = values[index + 1]
        let denominator = left - 2 * center + right
        return denominator == 0 ? 0 : CGFloat(0.5 * (left - right) / denominator)
    }
}

/// An 8-bit grayscale copy of an image, for analysis.
struct GrayImage {
    let width: Int
    let height: Int
    let pixels: [UInt8]

    init(image: CGImage, scale: CGFloat) throws {
        width = max(1, Int(CGFloat(image.width) * scale))
        height = max(1, Int(CGFloat(image.height) * scale))
        guard width > 2 * GridDetector.minimumSpacing, height > 2 * GridDetector.minimumSpacing else {
            throw GridDetectionError.imageTooSmall
        }
        var buffer = [UInt8](repeating: 0, count: width * height)
        let (w, h) = (width, height)
        buffer.withUnsafeMutableBytes { bytes in
            let context = CGContext(data: bytes.baseAddress, width: w, height: h, bitsPerComponent: 8,
                                    bytesPerRow: w, space: CGColorSpaceCreateDeviceGray(),
                                    bitmapInfo: CGImageAlphaInfo.none.rawValue)
            context?.interpolationQuality = .high
            context?.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        }
        pixels = buffer
    }

    /// Horizontal edge strength summed down each column (peaks at vertical grid lines).
    func columnEdgeProfile() -> [Double] {
        var profile = [Double](repeating: 0, count: width - 1)
        for y in 0..<height {
            let row = y * width
            for x in 0..<(width - 1) {
                profile[x] += Double(abs(Int(pixels[row + x + 1]) - Int(pixels[row + x])))
            }
        }
        return profile
    }

    /// Vertical edge strength summed along each row (peaks at horizontal grid lines).
    func rowEdgeProfile() -> [Double] {
        (0..<(height - 1)).map { y in
            let row = y * width, next = row + width
            var sum = 0
            for x in 0..<width { sum += abs(Int(pixels[next + x]) - Int(pixels[row + x])) }
            return Double(sum)
        }
    }
}
