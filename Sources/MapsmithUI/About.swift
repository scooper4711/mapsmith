import AppNotices
import Foundation

extension AboutInfo {
    /// Mapsmith's About screen, whose notices match the README's Paizo notices. It ships no third-party content.
    static let mapsmith = AboutInfo(
        appName: "Mapsmith",
        tagline: "An unofficial, free app that prints battle maps at one inch per square on ordinary paper.",
        credits: [],
        // A literal URL that is known to parse.
        // swiftlint:disable:next force_unwrapping
        contactURL: URL(string: "https://github.com/scooper4711/mapsmith/issues")!
    )
}
