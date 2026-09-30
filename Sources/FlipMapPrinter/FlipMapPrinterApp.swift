import AppKit
import SwiftUI

@main
struct FlipMapPrinterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var model = AppModel.shared

    var body: some Scene {
        Window("Flip Map Printer", id: "main") {
            ContentView()
                .environment(model)
                .frame(minWidth: 900, minHeight: 600)
        }
        .defaultSize(width: 1300, height: 850)
        .commands { AppCommands(model: model) }
    }
}

/// File-menu commands: open, export and print.
struct AppCommands: Commands {
    let model: AppModel

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Open…") { model.showOpenPanel() }
                .keyboardShortcut("o")
        }
        CommandGroup(after: .saveItem) {
            Button("Export Tiles as PDF…") { model.exportPDF() }
                .keyboardShortcut("e")
                .disabled(model.plan == nil)
        }
        CommandGroup(replacing: .printItem) {
            Button("Page Setup…") { model.runPageSetup() }
                .keyboardShortcut("p", modifiers: [.command, .shift])
            Button("Print Tiles…") { model.printTiles() }
                .keyboardShortcut("p")
                .disabled(model.plan == nil)
        }
    }
}

/// Handles files opened from Finder (double-click, drag onto the Dock icon, Open With).
final class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        MainActor.assumeIsolated { AppModel.shared.open(url) }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
