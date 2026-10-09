import AppKit
import MapsmithCore
import SwiftUI

@main
struct MapsmithApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // One window per file, as in Preview. Opening a file that already has a window brings it forward.
        WindowGroup(for: URL.self) { $url in
            DocumentWindow(url: url, router: appDelegate.router, recents: appDelegate.recents)
                .frame(minWidth: 900, minHeight: 600)
        }
        .defaultSize(width: 1300, height: 850)
        .commands { AppCommands(router: appDelegate.router, recents: appDelegate.recents) }
    }
}

/// File-menu commands: open, open recent, export and print. Export and print act on the frontmost window.
struct AppCommands: Commands {
    let router: DocumentRouter
    @ObservedObject var recents: RecentDocuments
    @FocusedValue(\.documentModel) private var model

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Open…") { router.open(OpenPanel.chooseFiles()) }
                .keyboardShortcut("o")
            Menu("Open Recent") {
                ForEach(recents.urls, id: \.self) { url in
                    Button(url.lastPathComponent) { router.open([url]) }
                }
                Divider()
                Button("Clear Menu") { recents.clear() }
                    .disabled(recents.urls.isEmpty)
            }
        }
        CommandGroup(after: .saveItem) {
            Button("Export Tiles as PDF…") { model?.exportPDF() }
                .keyboardShortcut("e")
                .disabled(model?.plan == nil)
        }
        CommandGroup(replacing: .printItem) {
            Button("Page Setup…") { model?.runPageSetup() }
                .keyboardShortcut("p", modifiers: [.command, .shift])
                .disabled(model == nil)
            Button("Print Tiles…") { model?.printTiles() }
                .keyboardShortcut("p")
                .disabled(model?.plan == nil)
        }
    }
}

extension FocusedValues {
    /// The model of the frontmost document window, for the menu bar.
    @Entry var documentModel: AppModel?
}

@MainActor
enum OpenPanel {
    /// Asks the user for PDFs or images to open; empty if they cancel.
    static func chooseFiles() -> [URL] {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf, .image]
        panel.allowsMultipleSelection = true
        return panel.runModal() == .OK ? panel.urls : []
    }
}

/// Handles files opened from Finder (double-click, drag onto the Dock icon, Open With).
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let router = DocumentRouter()
    let recents = RecentDocuments(store: SystemRecentDocuments())

    func application(_ application: NSApplication, open urls: [URL]) {
        router.open(urls)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

/// The system's recent-documents list, which also feeds the Dock icon's menu.
struct SystemRecentDocuments: RecentDocumentStore {
    var urls: [URL] { NSDocumentController.shared.recentDocumentURLs }

    func note(_ url: URL) { NSDocumentController.shared.noteNewRecentDocumentURL(url) }

    func clear() { NSDocumentController.shared.clearRecentDocuments(nil) }
}

/// A window and the one file it shows. `url` is the window's identity, which SwiftUI also uses
/// to restore the window on relaunch. A window without one is the empty window shown at launch.
struct DocumentWindow: View {
    let url: URL?
    let router: DocumentRouter
    let recents: RecentDocuments

    @State private var model = AppModel()
    @State private var windowID = UUID()
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ContentView()
            .environment(model)
            .environment(router)
            .focusedSceneValue(\.documentModel, model)
            .task(id: url) { showDocument() }
            // File-open events go to `AppDelegate`. Accepting them here as well stops SwiftUI
            // opening an extra empty window for each one while a window already exists.
            .handlesExternalEvents(preferring: ["*"], allowing: ["*"])
            .onChange(of: router.pendingURLs, initial: true) { openPendingDocuments() }
            .task(id: router.hasDocumentWindows) { closeIfSuperseded() }
            .onChange(of: model.fileURL) { noteIfOpened() }
            .onDisappear { router.documentWindowDidClose(windowID) }
    }

    private func showDocument() {
        guard let url else { return }
        router.documentWindowDidAppear(windowID)
        model.open(url)
    }

    private func openPendingDocuments() {
        router.claimPending().forEach { openWindow(value: $0) }
    }

    /// The empty window only exists until a file is open. SwiftUI also creates one for each
    /// file-open event at launch, and those close the same way. This runs as a task because a
    /// window cannot be dismissed while it is still appearing.
    private func closeIfSuperseded() {
        if url == nil, router.hasDocumentWindows { dismiss() }
    }

    private func noteIfOpened() {
        if let url = model.fileURL { recents.note(url) }
    }
}
