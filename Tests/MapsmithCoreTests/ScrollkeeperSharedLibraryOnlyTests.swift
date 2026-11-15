import Foundation
import Testing
@testable import MapsmithCore

/// The bridge where Scrollkeeper takes no requests, as on the iPad: only the shared library is read.
@MainActor @Suite struct ScrollkeeperSharedLibraryOnlyTests {
    let launcher: FakeLauncher = {
        let launcher = FakeLauncher()
        launcher.takesRequests = false
        return launcher
    }()
    let folder = FakeScrollkeeperFolder()

    @Test func saysThereIsNoSharedLibraryInsteadOfAsking() {
        let bridge = ScrollkeeperBridge(launcher: launcher, libraryFolder: folder.url)
        bridge.requestIndex()
        #expect(bridge.state == .noSharedLibrary)
        #expect(launcher.backgroundURLs.isEmpty)
        #expect(!bridge.takesRequests)
    }

    @Test func readsTheLibraryOnceScrollkeeperSharesIt() throws {
        let bridge = ScrollkeeperBridge(launcher: launcher, libraryFolder: folder.url)
        bridge.requestIndex()
        try folder.writeLibrary(titles: [FakeScrollkeeperFolder.title("MAP1")])

        bridge.refreshLibrary()

        guard case let .loaded(index) = bridge.state else { throw ScrollkeeperLibraryTestError.notLoaded }
        #expect(index.titles.map(\.sku) == ["MAP1"])
    }

    @Test func bringsScrollkeeperForwardForATitleNotDownloaded() {
        let bridge = ScrollkeeperBridge(launcher: launcher, libraryFolder: folder.url)
        let entry = ScrollkeeperIndex.Entry(sku: "PZO1", title: "Forest", downloaded: false)

        bridge.open(entry)
        bridge.download(entry)

        #expect(launcher.launched == [ScrollkeeperBridge.bundleIdentifier, ScrollkeeperBridge.bundleIdentifier])
        #expect(launcher.backgroundURLs.isEmpty)
        #expect(bridge.request(for: entry) == nil)
    }

    @Test func opensADownloadedTitleFromTheSharedFolder() {
        let bridge = ScrollkeeperBridge(launcher: launcher, libraryFolder: folder.url)
        var opened: [URL] = []
        bridge.openDocuments = { opened = $0 }
        var entry = ScrollkeeperIndex.Entry(sku: "PZO1", title: "Forest")
        entry.localFiles = [URL(filePath: "/shared/forest.pdf")]

        bridge.open(entry)

        #expect(opened == [URL(filePath: "/shared/forest.pdf")])
        #expect(launcher.launched.isEmpty)
    }

    @Test func leavesAnInstalledCheckFirst() {
        launcher.installed = false
        let bridge = ScrollkeeperBridge(launcher: launcher, libraryFolder: folder.url)
        bridge.requestIndex()
        #expect(bridge.state == .notInstalled)
    }
}
