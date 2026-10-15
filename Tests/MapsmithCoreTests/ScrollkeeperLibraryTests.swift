import Foundation
import Testing
@testable import MapsmithCore

/// Stands in for `NSWorkspace`, recording what was asked of it.
@MainActor
final class FakeLauncher: ApplicationLauncher {
    var installed: Set<String> = [ScrollkeeperLibrary.bundleIdentifier]
    private(set) var openedURLs: [URL] = []
    private(set) var launched: [String] = []

    func isInstalled(_ bundleIdentifier: String) -> Bool { installed.contains(bundleIdentifier) }
    func open(_ url: URL) { openedURLs.append(url) }
    func launch(_ bundleIdentifier: String) { launched.append(bundleIdentifier) }
}

@MainActor @Suite struct ScrollkeeperLibraryTests {
    let launcher = FakeLauncher()
    let forest: [String: Any] = ["sku": "PZO31005", "title": "Flip-Mat Classics: Forest", "series": "Flip-Mat Classics"]
    let tavern: [String: Any] = ["sku": "PZO30098", "title": "Flip-Mat: Tavern", "number": 3]

    @Test func readsTheTitlesScrollkeeperListed() throws {
        let url = try TestSupport.writeMapIndex(titles: [forest, tavern])
        let state = ScrollkeeperLibrary(launcher: launcher, indexURL: url).state()

        guard case let .loaded(index) = state else {
            Issue.record("expected a loaded index, got \(state)")
            return
        }
        #expect(index.titles.map(\.sku) == ["PZO31005", "PZO30098"])
        #expect(index.titles[0].subtitle == "Flip-Mat Classics")
        #expect(index.titles[1].subtitle == "#3")
        #expect(index.generatedAt == Date(timeIntervalSince1970: 1_792_087_200))
    }

    @Test func saysWhenScrollkeeperIsNotInstalled() throws {
        launcher.installed = []
        let url = try TestSupport.writeMapIndex(titles: [forest])
        #expect(ScrollkeeperLibrary(launcher: launcher, indexURL: url).state() == .notInstalled)
    }

    @Test func saysWhenThereIsNoListYet() {
        let missing = FileManager.default.temporaryDirectory.appendingPathComponent("missing-\(UUID()).json")
        #expect(ScrollkeeperLibrary(launcher: launcher, indexURL: missing).state() == .noCatalog)
    }

    @Test func treatsAnUnreadableListAsMissing() throws {
        let garbled = FileManager.default.temporaryDirectory.appendingPathComponent("garbled-\(UUID()).json")
        try Data("{\"formatVersion\": 1}".utf8).write(to: garbled)
        #expect(ScrollkeeperLibrary(launcher: launcher, indexURL: garbled).state() == .noCatalog)
    }

    @Test func refusesANewerFormat() throws {
        let url = try TestSupport.writeMapIndex(version: 2, titles: [forest])
        #expect(ScrollkeeperLibrary(launcher: launcher, indexURL: url).state() == .unsupportedVersion)
    }

    @Test func asksScrollkeeperToOpenATitleInMapsmith() {
        let library = ScrollkeeperLibrary(launcher: launcher)
        library.open(ScrollkeeperMapIndex.Entry(sku: "PZO 31&005", title: "Odd"))

        #expect(launcher.openedURLs.map(\.absoluteString) == ["scrollkeeper://open?sku=PZO%2031%26005&app=mapsmith"])
    }

    @Test func bringsScrollkeeperForward() {
        ScrollkeeperLibrary(launcher: launcher).launch()
        #expect(launcher.launched == [ScrollkeeperLibrary.bundleIdentifier])
    }

    @Test func looksForTheListInScrollkeepersFolder() {
        #expect(ScrollkeeperLibrary.defaultIndexURL.path.hasSuffix(
            "Library/Application Support/Scrollkeeper/Shared/maps.json"
        ))
    }
}

@Suite struct ScrollkeeperMapSearchTests {
    let index = ScrollkeeperMapIndex(generatedAt: .now, titles: [
        .init(sku: "A", title: "Flip-Mat Classics: Forest", series: "Flip-Mat Classics"),
        .init(sku: "B", title: "Flip-Mat: Haunted Dungeons"),
        .init(sku: "C", title: "Poster Map Folio: Kingmaker"),
        .init(sku: "D", title: "Flip-Tiles: Château Ruins")
    ])

    @Test func emptySearchListsEverything() {
        #expect(index.search("  ").map(\.sku) == ["A", "B", "C", "D"])
    }

    @Test func everyWordMustMatch() {
        #expect(index.search("flip forest").map(\.sku) == ["A"])
        #expect(index.search("flip").map(\.sku) == ["A", "B", "D"])
    }

    @Test func ignoresCaseAndAccents() {
        #expect(index.search("CHATEAU").map(\.sku) == ["D"])
    }

    @Test func matchesTheSeriesToo() {
        #expect(index.search("classics").map(\.sku) == ["A"])
    }

    @Test func findsNothingForUnknownWords() {
        #expect(index.search("starship").isEmpty)
    }
}
