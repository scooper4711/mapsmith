#if os(iOS)
import UIKit

/// Prints a tile PDF on the iPad exactly as laid out. Handing the PDF to the print panel as a printing item would
/// scale each page to the printer's printable area; this draws every page at the paper's origin at 100% instead,
/// and asks the printer for the paper the tiles were planned for.
@MainActor
enum TilePrinter {
    static func print(_ data: Data, title: String, paperSize: CGSize, printerURL: URL?) {
        guard let provider = CGDataProvider(data: data as CFData), let document = CGPDFDocument(provider) else {
            return
        }
        let info = UIPrintInfo.printInfo()
        info.jobName = title
        info.outputType = .general
        info.orientation = .portrait
        info.printerID = printerURL?.absoluteString

        let controller = UIPrintInteractionController.shared
        let delegate = PaperChooser(paperSize: paperSize)
        controller.printInfo = info
        controller.printPageRenderer = ActualSizeRenderer(document: document)
        controller.delegate = delegate
        controller.present(animated: true) { _, _, _ in
            // The controller holds its delegate weakly; this keeps it until the print panel is done.
            withExtendedLifetime(delegate) {}
        }
    }
}

/// Asks the printer for the paper the tiles were planned for, or the closest it has.
private final class PaperChooser: NSObject, UIPrintInteractionControllerDelegate {
    let paperSize: CGSize

    init(paperSize: CGSize) {
        self.paperSize = paperSize
    }

    func printInteractionController(_ controller: UIPrintInteractionController,
                                    choosePaper paperList: [UIPrintPaper]) -> UIPrintPaper {
        UIPrintPaper.bestPaper(forPageSize: paperSize, withPapersFrom: paperList)
    }
}

/// Draws each page of the PDF at the paper's top-left corner, one PDF point to one printed point.
private final class ActualSizeRenderer: UIPrintPageRenderer {
    private let document: CGPDFDocument

    init(document: CGPDFDocument) {
        self.document = document
    }

    override var numberOfPages: Int { document.numberOfPages }

    override func drawPage(at pageIndex: Int, in printableRect: CGRect) {
        guard let page = document.page(at: pageIndex + 1), let context = UIGraphicsGetCurrentContext() else { return }
        let box = page.getBoxRect(.mediaBox)
        context.saveGState()
        // The context is in paper coordinates with the origin at the top left; PDF pages have theirs at the
        // bottom left.
        context.translateBy(x: paperRect.minX, y: paperRect.minY + box.height)
        context.scaleBy(x: 1, y: -1)
        context.translateBy(x: -box.minX, y: -box.minY)
        context.drawPDFPage(page)
        context.restoreGState()
    }
}
#endif
