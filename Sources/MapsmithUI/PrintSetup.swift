#if os(macOS)
import AppKit
import MapsmithCore
import PDFKit

/// A window's print settings (`NSPrintInfo`) and the tiling geometry they give.
@MainActor
final class PrintSetup {
    private static let store = PageSetupStore()

    /// Each window has its own page setup, starting from the one most recently chosen in any window.
    let printInfo = NSPrintInfo.shared.copy() as? NSPrintInfo ?? .shared

    /// Makes the page setup chosen in an earlier launch the starting point for this launch's windows. Without
    /// one they start from the system's default, which is formatted for "Any Printer".
    static func restoreSavedSetup() {
        if let saved = store.savedSetup { NSPrintInfo.shared = saved }
    }

    /// The printable page, in PDF page coordinates.
    var page: PageGeometry {
        let paper = printInfo.paperSize
        let imageable = printInfo.imageablePageBounds
        guard paper.width > 0, paper.height > 0, imageable.width > 0, imageable.height > 0 else {
            return .a4Default
        }
        return PageGeometry(paperSize: paper, imageableRect: imageable)
    }

    var printerName: String { printInfo.printer.name }

    var paperName: String { printInfo.localizedPaperName ?? "Custom" }

    /// Shows the standard Page Setup sheet. Returns true when the user pressed OK; the choice then also becomes
    /// the starting point for new windows, in this launch and the following ones.
    func runPageSetup() -> Bool {
        guard NSPageLayout().runModal(with: printInfo) == NSApplication.ModalResponse.OK.rawValue else { return false }
        if let chosen = printInfo.copy() as? NSPrintInfo { NSPrintInfo.shared = chosen }
        Self.store.save(printInfo)
        return true
    }

    /// Prints a tile PDF exactly as laid out: no scaling, rotation or margins added.
    func printTiles(_ data: Data, title: String) {
        guard let document = PDFDocument(data: data) else { return }
        guard let info = printInfo.copy() as? NSPrintInfo else { return }
        info.topMargin = 0
        info.bottomMargin = 0
        info.leftMargin = 0
        info.rightMargin = 0
        info.isHorizontallyCentered = false
        info.isVerticallyCentered = false
        guard let operation = document.printOperation(for: info, scalingMode: .pageScaleNone, autoRotate: false)
        else { return }
        operation.jobTitle = title
        operation.showsPrintPanel = true
        operation.showsProgressPanel = true
        if let window = NSApp.keyWindow {
            operation.runModal(for: window, delegate: nil, didRun: nil, contextInfo: nil)
        } else {
            operation.run()
        }
    }
}

extension AppModel {
    func runPageSetup() {
        if printSetup.runPageSetup() { refreshPage() }
    }
}
#endif
