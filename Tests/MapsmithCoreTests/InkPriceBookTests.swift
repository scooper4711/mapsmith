import Foundation
import Testing
@testable import MapsmithCore

@MainActor @Suite struct InkPriceBookTests {
    private let suiteName = "InkPriceBookTests.\(UUID().uuidString)"

    private func makeDefaults() throws -> UserDefaults {
        try #require(UserDefaults(suiteName: suiteName))
    }

    @Test func aPrinterWithoutSavedPricesHasNone() throws {
        let book = InkPriceBook(defaults: try makeDefaults())
        #expect(book.savedSet(for: "Nick Canon") == nil)
        #expect(book.completeSet(for: "Nick Canon") == nil)
    }

    @Test func savedPricesAreKeptPerPrinterAcrossLaunches() throws {
        let defaults = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        InkPriceBook(defaults: defaults).save(InkSetTests.canonXL, for: "Nick Canon")

        let relaunched = InkPriceBook(defaults: defaults)
        #expect(relaunched.savedSet(for: "Nick Canon") == InkSetTests.canonXL)
        #expect(relaunched.completeSet(for: "Nick Canon") == InkSetTests.canonXL)
        #expect(relaunched.savedSet(for: "Xerox") == nil)
    }

    @Test func anIncompleteSetIsSavedButNotUsedForEstimates() throws {
        let defaults = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let book = InkPriceBook(defaults: defaults)
        book.save(InkSet.defaults(from: []), for: "Nick Canon")
        #expect(book.savedSet(for: "Nick Canon") != nil)
        #expect(book.completeSet(for: "Nick Canon") == nil)
    }
}
