#if os(iOS)
import MapsmithCore
import SwiftUI
import TablesideShared
import UIKit

/// The iPad and iPhone app: one window showing one map. Opening another file replaces it.
public struct MapsmithApp: App {
    @State private var inkPrices = InkPriceBook()
    @State private var clipboard = ClipboardWatcher()

    public init() {}

    public var body: some Scene {
        WindowGroup {
            PadRootView()
                .environment(inkPrices)
        }
        .commands { PadCommands(clipboard: clipboard) }
    }
}

/// File-menu commands for a hardware keyboard and the iPad's menu bar.
struct PadCommands: Commands {
    let clipboard: ClipboardWatcher
    @FocusedValue(\.documentRouter) private var router

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("New from Clipboard") { if let router { clipboard.open(with: router) } }
                .keyboardShortcut("n", modifiers: [.command, .option])
                .disabled(router == nil || !clipboard.hasMap)
        }
    }
}

extension FocusedValues {
    /// The router of the frontmost window, for the menu bar.
    @Entry var documentRouter: DocumentRouter?
}

/// The window: the map, the file browser, and the Open from Scrollkeeper and Ink Prices sheets.
struct PadRootView: View {
    @State private var model = AppModel()
    @State private var router = DocumentRouter()
    @State private var scrollkeeper = ScrollkeeperBridge(launcher: PadLauncher(),
                                                         libraryFolder: ToolkitGroup.scrollkeeperFolder())
    @State private var libraryChanges: LibraryChangeObserver?
    @State private var isChoosingFile = false
    @State private var isShowingScrollkeeper = false
    @State private var isShowingInkPrices = false
    @Environment(InkPriceBook.self) private var inkPrices
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ContentView()
            .environment(model)
            .environment(router)
            .environment(\.documentActions, DocumentActions(
                open: { isChoosingFile = true },
                openFromScrollkeeper: { isShowingScrollkeeper = true },
                showInkPrices: { isShowingInkPrices = true }))
            .focusedSceneValue(\.documentRouter, router)
            .fileImporter(isPresented: $isChoosingFile, allowedContentTypes: [.pdf, .image]) { result in
                switch result {
                case let .success(url): router.open([url])
                case let .failure(error): model.errorMessage = "Opening failed: \(error.localizedDescription)"
                }
            }
            .sheet(isPresented: $isShowingScrollkeeper) { scrollkeeperSheet }
            .sheet(isPresented: $isShowingInkPrices) { inkPricesSheet }
            .onOpenURL { router.open([$0]) }
            .onChange(of: router.pendingURLs, initial: true) { openPending() }
            .onChange(of: scenePhase) { if scenePhase == .active { scrollkeeper.refreshLibrary() } }
            .onAppear(perform: startFollowingScrollkeeper)
            #if DEBUG
            .task { if let sample = UITestSample.urlIfRequested() { router.open([sample]) } }
            #endif
    }

    private var scrollkeeperSheet: some View {
        NavigationStack {
            ScrollkeeperBrowser(bridge: scrollkeeper) { isShowingScrollkeeper = false }
                .navigationTitle("Open from Scrollkeeper")
                .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var inkPricesSheet: some View {
        NavigationStack {
            InkSettingsView(book: inkPrices)
                .environment(model)
                .navigationTitle("Ink Prices")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { isShowingInkPrices = false }
                    }
                }
        }
    }

    /// The iPad shows one file, so of several waiting only the newest opens.
    private func openPending() {
        guard let url = router.claimPending().last else { return }
        isShowingScrollkeeper = false
        model.open(url)
    }

    /// Scrollkeeper says when it rewrites its library list, so an open list follows its downloads.
    private func startFollowingScrollkeeper() {
        scrollkeeper.openDocuments = { [router] urls in router.open(urls) }
        guard libraryChanges == nil else { return }
        libraryChanges = LibraryChangeObserver { [scrollkeeper] in scrollkeeper.refreshLibrary() }
    }
}

/// The system side of `ApplicationLauncher` on the iPad. Scrollkeeper there takes no requests: Mapsmith only reads
/// its shared library and brings it forward to download a map.
struct PadLauncher: ApplicationLauncher {
    // A literal URL that is known to parse.
    // swiftlint:disable:next force_unwrapping
    private static let scrollkeeperURL = URL(string: "scrollkeeper://")!

    var takesRequests: Bool { false }

    /// Scrollkeeper's link, when it registers one, or else its folder in the App Group, which it makes on its
    /// first launch.
    func isInstalled(_ bundleIdentifier: String) -> Bool {
        if UIApplication.shared.canOpenURL(Self.scrollkeeperURL) { return true }
        guard let folder = ToolkitGroup.scrollkeeperFolder() else { return false }
        return FileManager.default.fileExists(atPath: folder.path)
    }

    func openInBackground(_ url: URL) {}

    func launch(_ bundleIdentifier: String) {
        UIApplication.shared.open(Self.scrollkeeperURL)
    }
}
#endif
