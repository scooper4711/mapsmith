import AppKit
import MapsmithCore
import PDFKit

/// Bridges the app's print settings (`NSPrintInfo`) to the tiling geometry.
@MainActor
enum PrintSetup {
    /// The printable page described by `printInfo`, in PDF page coordinates.
    static func geometry(of printInfo: NSPrintInfo) -> PageGeometry {
        let paper = printInfo.paperSize
        let imageable = printInfo.imageablePageBounds
        guard paper.width > 0, paper.height > 0, imageable.width > 0, imageable.height > 0 else {
            return .a4Default
        }
        return PageGeometry(paperSize: paper, imageableRect: imageable)
    }

    static func printerName(of printInfo: NSPrintInfo) -> String {
        printInfo.printer.name
    }

    static func paperName(of printInfo: NSPrintInfo) -> String {
        printInfo.localizedPaperName ?? "Custom"
    }

    /// Shows the standard Page Setup sheet. Returns true when the user pressed OK.
    static func runPageSetup(_ printInfo: NSPrintInfo) -> Bool {
        NSPageLayout().runModal(with: printInfo) == NSApplication.ModalResponse.OK.rawValue
    }

    /// Prints a tile PDF exactly as laid out: no scaling, rotation or margins added.
    static func printTiles(_ data: Data, title: String, printInfo: NSPrintInfo) {
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
