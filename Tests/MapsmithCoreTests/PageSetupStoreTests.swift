#if os(macOS)
import AppKit
import Testing
@testable import MapsmithCore

@MainActor @Suite struct PageSetupStoreTests {
    private let suiteName = "PageSetupStoreTests.\(UUID().uuidString)"

    private func makeDefaults() throws -> UserDefaults {
        try #require(UserDefaults(suiteName: suiteName))
    }

    /// A page setup that differs from the system's default in paper and orientation.
    private func makeLandscapeA3() -> NSPrintInfo {
        let setup = NSPrintInfo()
        setup.paperSize = CGSize(width: 841.89, height: 1190.55)
        setup.orientation = .landscape
        return setup
    }

    @Test func nothingIsSavedUntilAPageSetupIsChosen() throws {
        #expect(PageSetupStore(defaults: try makeDefaults()).savedSetup == nil)
    }

    @Test func theChosenPageSetupIsKeptAcrossLaunches() throws {
        let defaults = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let chosen = makeLandscapeA3()
        PageSetupStore(defaults: defaults).save(chosen)

        let restored = try #require(PageSetupStore(defaults: defaults).savedSetup)
        #expect(restored.paperSize == chosen.paperSize)
        #expect(restored.orientation == .landscape)
        #expect(restored.imageablePageBounds == chosen.imageablePageBounds)
        #expect(restored.printer.name == chosen.printer.name)
    }

    @Test func aLaterChoiceReplacesTheSavedOne() throws {
        let defaults = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = PageSetupStore(defaults: defaults)
        store.save(makeLandscapeA3())
        let portrait = makeLandscapeA3()
        portrait.orientation = .portrait
        store.save(portrait)

        #expect(store.savedSetup?.orientation == .portrait)
    }

    @Test func aSavedSetupThatCannotBeReadIsIgnored() throws {
        let defaults = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(Data("not a page setup".utf8), forKey: PageSetupStore.key)

        #expect(PageSetupStore(defaults: defaults).savedSetup == nil)
    }
}
#endif
