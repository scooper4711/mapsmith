import Foundation
import Testing
@testable import MapsmithCore

@MainActor @Suite struct DocumentRouterTests {
    let router = DocumentRouter()
    let first = URL(fileURLWithPath: "/tmp/first.pdf")
    let second = URL(fileURLWithPath: "/tmp/second.png")

    @Test func pendingFilesAreHandedOutOnceInOrder() {
        router.open([first])
        router.open([second])

        #expect(router.claimPending() == [first, second])
        #expect(router.pendingURLs.isEmpty)
        #expect(router.claimPending().isEmpty)
    }

    @Test func tracksWhetherAnyDocumentWindowIsOpen() {
        let windows = [UUID(), UUID()]
        #expect(!router.hasDocumentWindows)

        windows.forEach(router.documentWindowDidAppear)
        router.documentWindowDidClose(windows[0])
        #expect(router.hasDocumentWindows)

        router.documentWindowDidClose(windows[1])
        #expect(!router.hasDocumentWindows)
    }

    @Test func recentFilesAreNewestFirstWithoutRepeats() {
        let store = FakeRecentStore(urls: [first])
        let recents = RecentDocuments(store: store)
        #expect(recents.urls == [first])

        recents.note(second)
        recents.note(first)
        #expect(recents.urls == [first, second])
        #expect(store.urls == [first, second])
    }

    @Test func recentFilesAreCappedAndCanBeCleared() {
        let store = FakeRecentStore(urls: [])
        let recents = RecentDocuments(store: store)
        for index in 0..<(RecentDocuments.maximumCount + 3) {
            recents.note(URL(fileURLWithPath: "/tmp/map\(index).pdf"))
        }
        #expect(recents.urls.count == RecentDocuments.maximumCount)
        #expect(recents.urls.first?.lastPathComponent == "map12.pdf")

        recents.clear()
        #expect(recents.urls.isEmpty && store.urls.isEmpty)
    }
}

@MainActor
private final class FakeRecentStore: RecentDocumentStore {
    private(set) var urls: [URL]

    init(urls: [URL]) { self.urls = urls }

    func note(_ url: URL) {
        urls.removeAll { $0 == url }
        urls.insert(url, at: 0)
    }

    func clear() { urls = [] }
}
