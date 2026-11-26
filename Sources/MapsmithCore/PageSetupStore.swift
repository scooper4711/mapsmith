#if os(macOS)
import AppKit

/// The Mac's page setup (printer, paper and orientation), kept in `UserDefaults` so that the next launch starts
/// with the one the user last chose.
public struct PageSetupStore {
    static let key = "pageSetup"

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// The page setup that was saved; nil when none was, or when the saved one can no longer be read.
    public var savedSetup: NSPrintInfo? {
        guard let data = defaults.data(forKey: Self.key) else { return nil }
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSPrintInfo.self, from: data)
    }

    /// Saves the whole page setup: an archive keeps a paper only one printer has, such as a borderless size.
    public func save(_ setup: NSPrintInfo) {
        let data = try? NSKeyedArchiver.archivedData(withRootObject: setup, requiringSecureCoding: true)
        if let data { defaults.set(data, forKey: Self.key) }
    }
}
#endif
