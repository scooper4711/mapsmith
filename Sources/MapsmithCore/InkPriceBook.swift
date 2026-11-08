import Foundation
import Observation

/// The ink sets the user has entered, one per printer, kept in `UserDefaults`.
@MainActor @Observable
public final class InkPriceBook {
    static let keyPrefix = "inkSet."

    @ObservationIgnored private let defaults: UserDefaults
    /// Bumped on every save, so views reading a set update when it changes.
    private var revision = 0

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// The printer's saved ink set, if the user has entered one.
    public func savedSet(for printer: String) -> InkSet? {
        _ = revision
        guard let data = defaults.data(forKey: Self.keyPrefix + printer) else { return nil }
        return try? JSONDecoder().decode(InkSet.self, from: data)
    }

    /// The printer's saved set when it is complete enough to price a map.
    public func completeSet(for printer: String) -> InkSet? {
        savedSet(for: printer).flatMap { $0.isComplete ? $0 : nil }
    }

    public func save(_ set: InkSet, for printer: String) {
        guard let data = try? JSONEncoder().encode(set) else { return }
        defaults.set(data, forKey: Self.keyPrefix + printer)
        revision += 1
    }
}
