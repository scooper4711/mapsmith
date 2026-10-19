import Foundation
import Testing
@testable import MapsmithCore

/// Stands in for `NSWorkspace`, recording what was asked of it.
@MainActor
final class FakeLauncher: ApplicationLauncher {
    var installed = true
    private(set) var backgroundURLs: [URL] = []
    private(set) var launched: [String] = []

    func isInstalled(_ bundleIdentifier: String) -> Bool { installed }
    func openInBackground(_ url: URL) { backgroundURLs.append(url) }
    func launch(_ bundleIdentifier: String) { launched.append(bundleIdentifier) }
}

@MainActor @Suite struct ScrollkeeperBridgeTests {
    let launcher = FakeLauncher()
    let forest: [String: Any] = ["sku": "PZO31005", "title": "Flip-Mat Classics: Forest", "kind": "Maps",
                                 "series": "Flip-Mat Classics", "downloaded": true]
    let tavern: [String: Any] = ["sku": "PZO30098", "title": "Flip-Mat: Tavern", "kind": "Maps", "number": 3,
                                 "downloaded": false]

    @Test func asksScrollkeeperInTheBackgroundForTheList() {
        let bridge = ScrollkeeperBridge(launcher: launcher)
        bridge.requestIndex()
        #expect(bridge.state == .waiting)
        #expect(launcher.backgroundURLs.map(\.absoluteString) == ["scrollkeeper://index?app=mapsmith"])
    }

    @Test func saysWhenScrollkeeperIsNotInstalled() {
        launcher.installed = false
        let bridge = ScrollkeeperBridge(launcher: launcher)
        bridge.requestIndex()
        #expect(bridge.state == .notInstalled)
        #expect(launcher.backgroundURLs.isEmpty)
    }

    @Test func readsTheListScrollkeeperHandsOver() throws {
        let index = try loadedIndex(of: loadedBridge())
        #expect(index.titles.map(\.sku) == ["PZO31005", "PZO30098"])
        #expect(index.titles[0].subtitle == "Flip-Mat Classics")
        #expect(index.titles[1].subtitle == "#3")
        #expect(index.titles.map(\.downloaded) == [true, false])
        #expect(index.generatedAt == Date(timeIntervalSince1970: 1_792_087_200))
    }

    @Test func refusesANewerFormat() throws {
        let bridge = ScrollkeeperBridge(launcher: launcher)
        bridge.receive(try TestSupport.writeTitleIndex(version: 2, titles: [forest]))
        #expect(bridge.state == .unsupportedVersion)
    }

    @Test func saysWhenTheListCannotBeRead() throws {
        let bridge = ScrollkeeperBridge(launcher: launcher)
        bridge.receive(try TestSupport.writeIndexFile(Data("not json".utf8)))
        #expect(bridge.state == .unreadable)
        bridge.receive(try TestSupport.writeIndexFile(Data(#"{"formatVersion": 1}"#.utf8)))
        #expect(bridge.state == .unreadable)
    }

    @Test func asksScrollkeeperInTheBackgroundToOpenATitle() {
        let bridge = ScrollkeeperBridge(launcher: launcher)
        let entry = ScrollkeeperIndex.Entry(sku: "PZO 31&005", title: "Odd")
        bridge.open(entry)

        #expect(launcher.backgroundURLs.map(\.absoluteString)
            == ["scrollkeeper://open?sku=PZO%2031%26005&app=mapsmith"])
        #expect(bridge.request(for: entry) == ScrollkeeperRequest(sku: "PZO 31&005", opens: true, phase: .requested))
    }

    @Test func asksScrollkeeperToDownloadWithoutOpening() {
        let bridge = ScrollkeeperBridge(launcher: launcher)
        let entry = ScrollkeeperIndex.Entry(sku: "PZO31005", title: "Forest", downloaded: false)
        bridge.download(entry)

        #expect(launcher.backgroundURLs.map(\.absoluteString)
            == ["scrollkeeper://download?sku=PZO31005&app=mapsmith"])
        #expect(bridge.request(for: entry)?.opens == false)
    }

    @Test func followsTheStatusScrollkeeperReports() throws {
        let bridge = ScrollkeeperBridge(launcher: launcher)
        let entry = ScrollkeeperIndex.Entry(sku: "PZO1", title: "Forest", downloaded: false)
        bridge.open(entry)
        let status = { (query: String) in try #require(URL(string: "mapsmith://handoff?sku=PZO1&\(query)")) }

        bridge.receiveStatus(try status("state=downloading&fraction=0.42"))
        #expect(bridge.request(for: entry)?.phase == .downloading(0.42))
        bridge.receiveStatus(try #require(URL(string: "mapsmith://handoff?sku=OTHER&state=done")))
        bridge.receiveStatus(try status("state=sideways"))
        #expect(bridge.request(for: entry)?.phase == .downloading(0.42))
        bridge.receiveStatus(try status("state=done"))
        #expect(bridge.request(for: entry)?.phase == .done)
        bridge.receiveStatus(try status("state=failed&reason=Signed%20out"))
        #expect(bridge.request(for: entry)?.phase == .failed("Signed out"))
    }

    @Test func marksADownloadedTitleOnDisk() throws {
        let bridge = try loadedBridge()
        let tavern = try #require(try loadedIndex(of: bridge).titles.last)
        bridge.download(tavern)

        bridge.receiveStatus(try #require(URL(string: "mapsmith://handoff?sku=PZO30098&state=done")))

        #expect(try loadedIndex(of: bridge).titles.map(\.downloaded) == [true, true])
    }

    @Test func forgetsRequestsWhenTheListIsAskedForAgain() {
        let bridge = ScrollkeeperBridge(launcher: launcher)
        let entry = ScrollkeeperIndex.Entry(sku: "PZO1", title: "Forest")
        bridge.open(entry)
        bridge.requestIndex()
        #expect(bridge.request(for: entry) == nil)
    }

    @Test func showsWhyScrollkeeperCouldNotSendTheList() throws {
        let bridge = ScrollkeeperBridge(launcher: launcher)
        bridge.requestIndex()
        bridge.receiveStatus(try #require(URL(string: "mapsmith://handoff?sku=&state=failed&reason=Sign%20in")))
        #expect(bridge.state == .failed("Sign in"))
    }

    @Test func tellsAStatusLinkFromOtherLinks() throws {
        #expect(ScrollkeeperBridge.isStatusLink(try #require(URL(string: "mapsmith://handoff?sku=A&state=done"))))
        #expect(!ScrollkeeperBridge.isStatusLink(try #require(URL(string: "mapsmith://other"))))
        #expect(!ScrollkeeperBridge.isStatusLink(URL(filePath: "/x/forest.pdf")))
    }

    @Test func tellsTheListFromAMap() {
        #expect(ScrollkeeperIndex.isIndexFile(URL(filePath: "/x/mapsmith.scrollkeeperindex")))
        #expect(!ScrollkeeperIndex.isIndexFile(URL(filePath: "/x/forest.pdf")))
    }

    @Test func bringsScrollkeeperForward() {
        ScrollkeeperBridge(launcher: launcher).launchScrollkeeper()
        #expect(launcher.launched == [ScrollkeeperBridge.bundleIdentifier])
    }

    private func loadedBridge() throws -> ScrollkeeperBridge {
        let bridge = ScrollkeeperBridge(launcher: launcher)
        bridge.receive(try TestSupport.writeTitleIndex(titles: [forest, tavern]))
        return bridge
    }

    private func loadedIndex(of bridge: ScrollkeeperBridge) throws -> ScrollkeeperIndex {
        guard case let .loaded(index) = bridge.state else { throw LoadError.notLoaded(bridge.state) }
        return index
    }

    private enum LoadError: Error {
        case notLoaded(ScrollkeeperBridge.State)
    }
}

@Suite struct ScrollkeeperMapSearchTests {
    let index = ScrollkeeperIndex(generatedAt: .now, titles: [
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
