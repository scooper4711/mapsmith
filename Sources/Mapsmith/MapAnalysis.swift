import CoreGraphics
import MapsmithCore

/// A selected map loaded at full resolution, with a preview image and its print scale.
struct MapAnalysis: @unchecked Sendable {
    static let previewSize = 1600

    let map: LoadedMap
    let preview: CGImage
    let scale: ScaleSource

    /// Load `source`, detect its grid, and fall back to the file's own scale if detection fails.
    static func analyse(_ source: MapSource) throws -> MapAnalysis {
        let map = try MapLoader.load(source)
        return MapAnalysis(map: map, preview: downscaled(map.image), scale: scale(of: map))
    }

    static func scale(of map: LoadedMap) -> ScaleSource {
        do {
            return .detected(try GridDetector.spacing(in: map.image))
        } catch {
            let reason = "\(error)"
            guard let fallback = map.fallbackPixelsPerInch else { return .unavailable(reason: reason) }
            return .fallback(fallback, description: map.fallbackDescription, reason: reason)
        }
    }

    static func downscaled(_ image: CGImage) -> CGImage {
        let factor = min(1, CGFloat(previewSize) / CGFloat(max(image.width, image.height)))
        let width = max(1, Int(CGFloat(image.width) * factor)), height = max(1, Int(CGFloat(image.height) * factor))
        guard factor < 1,
              let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                                      space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                      bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
        else { return image }
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage() ?? image
    }
}
