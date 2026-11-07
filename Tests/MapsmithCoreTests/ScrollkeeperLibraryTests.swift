import Foundation
import Testing
@testable import MapsmithCore

/// A Scrollkeeper folder in a temporary directory, as Scrollkeeper leaves it in the App Group, removed afterward.
final class FakeScrollkeeperFolder {
    let url = FileManager.default.temporaryDirectory.appending(path: "Scrollkeeper-" + UUID().uuidString)
    var files: URL { url.appending(path: "Files") }

    deinit { try? FileManager.default.removeItem(at: url) }

    /// Writes `library.json` in Scrollkeeper's wire format.
    func writeLibrary(version: Int = 1, isShared: Bool = true, titles: [[String: Any]]) throws {
        let library: [String: Any] = ["formatVersion": version, "generatedAt": "2026-11-07T18:00:00Z",
                                      "downloadFolder": ["isShared": isShared], "titles": titles]
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        try JSONSerialization.data(withJSONObject: library).write(to: url.appending(path: "library.json"))
    }

    /// Creates an empty file at `path` in the download folder.
    func addFile(_ path: String) throws {
        let file = files.appending(path: path)
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data().write(to: file)
    }

    static func title(_ sku: String, kind: String = "Maps", cover: String? = nil,
                      editions: [[String: Any]] = []) -> [String: Any] {
        var title: [String: Any] = ["sku": sku, "title": "Title \(sku)", "kind": kind, "gameSystem": "Pathfinder 2E",
                                    "downloaded": editions.contains { $0["downloaded"] as? Bool == true },
                                    "editions": editions]
        title["cover"] = cover
        return title
    }

    static func edition(_ path: String, isFolder: Bool = false, downloaded: Bool = true,
                        outdated: Bool = false) -> [String: Any] {
        ["name": path, "path": path, "isFolder": isFolder, "downloaded": downloaded, "outdated": outdated]
    }
}

@MainActor @Suite struct ScrollkeeperLibraryTests {
    let launcher = FakeLauncher()
    let folder = FakeScrollkeeperFolder()

    private func loadedEntries() throws -> [ScrollkeeperIndex.Entry] {
        let bridge = ScrollkeeperBridge(launcher: launcher, libraryFolder: folder.url)
        bridge.requestIndex()
        guard case let .loaded(index) = bridge.state else { throw ScrollkeeperLibraryTestError.notLoaded }
        return index.titles
    }

    private func entry(_ sku: String) throws -> ScrollkeeperIndex.Entry {
        try #require(try loadedEntries().first { $0.sku == sku })
    }

    @Test func listsTheMapsFromTheLibraryWithoutAskingScrollkeeper() throws {
        try folder.writeLibrary(titles: [
            FakeScrollkeeperFolder.title("MAP1", cover: "Covers/MAP1.jpg"),
            FakeScrollkeeperFolder.title("BOOK", kind: "Rulebooks"),
            FakeScrollkeeperFolder.title("MAP2")
        ])

        let entries = try loadedEntries()
        #expect(entries.map(\.sku) == ["MAP1", "MAP2"])
        #expect(entries[0].coverURL == folder.url.appending(path: "Covers/MAP1.jpg"))
        #expect(entries[1].coverURL == nil)
        #expect(launcher.backgroundURLs.isEmpty)
    }

    @Test func opensASingleFileOnDiskStraightFromTheSharedFolder() throws {
        try folder.addFile("Forest/Forest.pdf")
        try folder.writeLibrary(titles: [FakeScrollkeeperFolder.title("MAP1", editions: [
            FakeScrollkeeperFolder.edition("Forest/Forest.pdf")
        ])])
        let bridge = ScrollkeeperBridge(launcher: launcher, libraryFolder: folder.url)
        var opened: [URL] = []
        bridge.openDocuments = { opened += $0 }
        bridge.requestIndex()

        bridge.open(try entry("MAP1"))

        #expect(opened == [folder.files.appending(path: "Forest/Forest.pdf")])
        #expect(launcher.backgroundURLs.isEmpty)
    }

    @Test func opensAnUnpackedArchivesPDFsBeforeItsImages() throws {
        for path in ["Pack/Pack/b.pdf", "Pack/Pack/a.pdf", "Pack/Pack/a.jpg", "Pack/Pack/notes.txt"] {
            try folder.addFile(path)
        }
        try folder.writeLibrary(titles: [FakeScrollkeeperFolder.title("MAP1", editions: [
            FakeScrollkeeperFolder.edition("Pack/Pack", isFolder: true)
        ])])

        #expect(try entry("MAP1").localFiles.map(\.lastPathComponent) == ["a.pdf", "b.pdf"])
    }

    @Test func opensAnArchivesImagesWhenItHasNoPDF() throws {
        try folder.addFile("Tiles/Tiles/2.png")
        try folder.addFile("Tiles/Tiles/1.jpg")
        try folder.writeLibrary(titles: [FakeScrollkeeperFolder.title("MAP1", editions: [
            FakeScrollkeeperFolder.edition("Tiles/Tiles", isFolder: true)
        ])])

        #expect(try entry("MAP1").localFiles.map(\.lastPathComponent) == ["1.jpg", "2.png"])
    }

    @Test func asksScrollkeeperForTitlesNotReadyInTheSharedFolder() throws {
        try folder.addFile("Old/Old.pdf")
        try folder.writeLibrary(titles: [
            FakeScrollkeeperFolder.title("OLD", editions: [
                FakeScrollkeeperFolder.edition("Old/Old.pdf", outdated: true)
            ]),
            FakeScrollkeeperFolder.title("NEW", editions: [FakeScrollkeeperFolder.edition("New/New.pdf",
                                                                                          downloaded: false)])
        ])
        let bridge = ScrollkeeperBridge(launcher: launcher, libraryFolder: folder.url)
        bridge.requestIndex()

        bridge.open(try entry("OLD"))

        #expect(try entry("NEW").localFiles.isEmpty)
        #expect(launcher.backgroundURLs.map(\.absoluteString) == ["scrollkeeper://open?sku=OLD&app=mapsmith"])
    }

    @Test func leavesAFolderTheUserChoseToScrollkeeper() throws {
        try folder.addFile("Forest/Forest.pdf")
        try folder.writeLibrary(isShared: false, titles: [FakeScrollkeeperFolder.title("MAP1", editions: [
            FakeScrollkeeperFolder.edition("Forest/Forest.pdf")
        ])])

        let map = try entry("MAP1")
        #expect(map.downloaded)
        #expect(map.localFiles.isEmpty)
    }

    @Test func asksScrollkeeperWhenThereIsNoLibraryItUnderstands() throws {
        let missing = ScrollkeeperBridge(launcher: launcher, libraryFolder: folder.url)
        missing.requestIndex()
        #expect(missing.state == .waiting)

        try folder.writeLibrary(version: 2, titles: [FakeScrollkeeperFolder.title("MAP1")])
        let newer = ScrollkeeperBridge(launcher: launcher, libraryFolder: folder.url)
        newer.requestIndex()
        #expect(newer.state == .waiting)

        try Data("{}".utf8).write(to: folder.url.appending(path: "library.json"))
        let unreadable = ScrollkeeperBridge(launcher: launcher, libraryFolder: folder.url)
        unreadable.requestIndex()
        #expect(unreadable.state == .waiting)
        #expect(launcher.backgroundURLs.count == 3)
    }

    @Test func followsTheLibraryWhenScrollkeeperRewritesIt() throws {
        try folder.writeLibrary(titles: [FakeScrollkeeperFolder.title("MAP1")])
        let bridge = ScrollkeeperBridge(launcher: launcher, libraryFolder: folder.url)
        bridge.requestIndex()

        try folder.writeLibrary(titles: [FakeScrollkeeperFolder.title("MAP1"), FakeScrollkeeperFolder.title("MAP2")])
        bridge.refreshLibrary()

        guard case let .loaded(index) = bridge.state else { throw ScrollkeeperLibraryTestError.notLoaded }
        #expect(index.titles.map(\.sku) == ["MAP1", "MAP2"])
    }

    @Test func keepsAListHandedOverWhenTheLibraryChanges() throws {
        let bridge = ScrollkeeperBridge(launcher: launcher, libraryFolder: folder.url)
        bridge.requestIndex()
        bridge.receive(try TestSupport.writeTitleIndex(titles: [["sku": "HANDED", "title": "Handed",
                                                                 "kind": "Maps", "downloaded": true]]))
        try folder.writeLibrary(titles: [FakeScrollkeeperFolder.title("MAP1")])

        bridge.refreshLibrary()

        guard case let .loaded(index) = bridge.state else { throw ScrollkeeperLibraryTestError.notLoaded }
        #expect(index.titles.map(\.sku) == ["HANDED"])
    }

    @Test func findsTheToolkitGroupAmongTheSignedGroups() {
        #expect(ScrollkeeperFolder.tablesideGroup(in: ["T.io.github.scooper4711.other",
                                                       "T.io.github.scooper4711.tableside"])
                == "T.io.github.scooper4711.tableside")
        #expect(ScrollkeeperFolder.tablesideGroup(in: []) == nil)
        #expect(ScrollkeeperFolder.url() == nil)
    }
}

enum ScrollkeeperLibraryTestError: Error {
    case notLoaded
}
