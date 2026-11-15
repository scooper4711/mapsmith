import Foundation
import MapsmithCore
import TablesideShared
import Testing

/// Open from Scrollkeeper as Mapsmith configures tabletop-kit's bridge, which has its own tests there.
@MainActor @Suite struct MapsmithScrollkeeperTests {
    let launcher = FakeLauncher()
    let folder = FakeScrollkeeperFolder()

    private func loadedBridge() -> ScrollkeeperBridge {
        let bridge = ScrollkeeperBridge(configuration: .mapsmith, launcher: launcher, libraryFolder: folder.url)
        bridge.requestIndex()
        return bridge
    }

    private func entries(of bridge: ScrollkeeperBridge) throws -> [ScrollkeeperIndex.Entry] {
        guard case let .loaded(index) = bridge.state else { throw ScrollkeeperTestError.notLoaded(bridge.state) }
        return index.titles
    }

    @Test func listsTheMapsFromTheLibraryWithoutTheirKind() throws {
        try folder.writeLibrary(titles: [
            FakeScrollkeeperFolder.title("MAP1", cover: "Covers/MAP1.jpg"),
            FakeScrollkeeperFolder.title("BOOK", kind: "Rulebooks", editions: [
                FakeScrollkeeperFolder.edition("Book/Book.pdf")
            ]),
            FakeScrollkeeperFolder.title("MAP2", series: "Flip-Mat Classics")
        ])

        let entries = try entries(of: loadedBridge())

        #expect(entries.map(\.sku) == ["MAP1", "MAP2"])
        #expect(entries.map(\.subtitle) == ["", "Flip-Mat Classics"])
        #expect(entries[0].coverURL == folder.url.appending(path: "Covers/MAP1.jpg"))
        #expect(launcher.backgroundURLs.isEmpty)
    }

    @Test func opensAMapsPDFStraightFromTheSharedFolder() throws {
        try folder.addFile("Forest/Forest.pdf")
        try folder.writeLibrary(titles: [FakeScrollkeeperFolder.title("MAP1", editions: [
            FakeScrollkeeperFolder.edition("Forest/Forest.pdf")
        ])])
        let bridge = loadedBridge()
        var opened: [URL] = []
        bridge.openDocuments = { opened += $0 }

        bridge.open(try #require(try entries(of: bridge).first))

        #expect(opened == [folder.files.appending(path: "Forest/Forest.pdf")])
        #expect(launcher.backgroundURLs.isEmpty)
    }

    @Test func opensAnArchivesImagesButNotItsOtherFiles() throws {
        try folder.addFile("Tiles/Tiles/2.png")
        try folder.addFile("Tiles/Tiles/1.jpg")
        try folder.addFile("Tiles/Tiles/readme.txt")
        try folder.writeLibrary(titles: [FakeScrollkeeperFolder.title("MAP1", editions: [
            FakeScrollkeeperFolder.edition("Tiles/Tiles", isFolder: true)
        ])])

        let map = try #require(try entries(of: loadedBridge()).first)

        #expect(map.localFiles.map(\.lastPathComponent) == ["1.jpg", "2.png"])
    }

    @Test func asksScrollkeeperAsMapsmithForTheListAndForATitle() {
        let bridge = loadedBridge()
        #expect(bridge.state == .waiting)

        bridge.open(ScrollkeeperIndex.Entry(sku: "MAP1", title: "Forest", downloaded: false))
        bridge.download(ScrollkeeperIndex.Entry(sku: "MAP2", title: "Tavern", downloaded: false))

        #expect(launcher.backgroundURLs.map(\.absoluteString) == [
            "scrollkeeper://index?app=mapsmith", "scrollkeeper://open?sku=MAP1&app=mapsmith",
            "scrollkeeper://download?sku=MAP2&app=mapsmith"
        ])
    }

    @Test func followsSeveralRequestsThroughItsStatusLinks() throws {
        let bridge = loadedBridge()
        bridge.open(ScrollkeeperIndex.Entry(sku: "MAP1", title: "Forest", downloaded: false))
        bridge.download(ScrollkeeperIndex.Entry(sku: "MAP2", title: "Tavern", downloaded: false))
        let done = try #require(URL(string: "mapsmith://handoff?sku=MAP2&state=done"))

        #expect(bridge.isStatusLink(done))
        bridge.receiveStatus(done)

        #expect(bridge.requests == [
            "MAP1": ScrollkeeperRequest(sku: "MAP1", opens: true, phase: .requested),
            "MAP2": ScrollkeeperRequest(sku: "MAP2", opens: false, phase: .done)
        ])
    }
}

/// Stands in for `NSWorkspace`, recording the links opened in the background.
@MainActor
final class FakeLauncher: ApplicationLauncher {
    private(set) var backgroundURLs: [URL] = []

    func isInstalled(_ bundleIdentifier: String) -> Bool { true }
    func openInBackground(_ url: URL) { backgroundURLs.append(url) }
    func launch(_ bundleIdentifier: String) {}
}

/// A Scrollkeeper folder in a temporary directory, as Scrollkeeper leaves it in the App Group, removed afterward.
final class FakeScrollkeeperFolder {
    let url = FileManager.default.temporaryDirectory.appending(path: "Scrollkeeper-" + UUID().uuidString)
    var files: URL { url.appending(path: "Files") }

    deinit { try? FileManager.default.removeItem(at: url) }

    /// Writes `library.json` in Scrollkeeper's wire format, with its downloads in the shared folder.
    func writeLibrary(titles: [[String: Any]]) throws {
        let library: [String: Any] = ["formatVersion": 1, "generatedAt": "2026-11-07T18:00:00Z",
                                      "downloadFolder": ["isShared": true], "titles": titles]
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        try JSONSerialization.data(withJSONObject: library).write(to: url.appending(path: "library.json"))
    }

    /// Creates an empty file at `path` in the download folder.
    func addFile(_ path: String) throws {
        let file = files.appending(path: path)
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data().write(to: file)
    }

    static func title(_ sku: String, kind: String = "Maps", series: String? = nil, cover: String? = nil,
                      editions: [[String: Any]] = []) -> [String: Any] {
        var title: [String: Any] = ["sku": sku, "title": "Title \(sku)", "kind": kind, "gameSystem": "Pathfinder 2E",
                                    "downloaded": !editions.isEmpty, "editions": editions]
        title["series"] = series
        title["cover"] = cover
        return title
    }

    /// An up-to-date edition on disk.
    static func edition(_ path: String, isFolder: Bool = false) -> [String: Any] {
        ["name": path, "path": path, "isFolder": isFolder, "downloaded": true, "outdated": false]
    }
}

enum ScrollkeeperTestError: Error {
    case notLoaded(ScrollkeeperBridge.State)
}
