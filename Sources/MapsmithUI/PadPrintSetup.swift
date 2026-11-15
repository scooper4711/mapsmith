#if os(iOS)
import MapsmithCore
import Observation
import UIKit

/// The iPad's print settings: there is no Page Setup, so the user picks the paper and the printer's unprintable
/// border, and the printer whose ink prices to use. All three are remembered.
@MainActor @Observable
final class PrintSetup {
    private enum Key {
        static let paper = "PaperChoice"
        static let margin = "PaperMarginInches"
        static let printer = "InkPrinterName"
        static let printerURL = "InkPrinterURL"
    }

    @ObservationIgnored private let defaults: UserDefaults

    var paper: PaperChoice { didSet { defaults.set(paper.rawValue, forKey: Key.paper) } }
    var marginInches: Double { didSet { defaults.set(marginInches, forKey: Key.margin) } }
    /// The printer chosen with the printer picker; empty until one is.
    private(set) var printerName: String
    /// The chosen printer, so the print panel starts on it.
    private(set) var printerURL: URL?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        paper = defaults.string(forKey: Key.paper).flatMap(PaperChoice.init(rawValue:))
            ?? .regionalDefault(regionCode: Locale.current.region?.identifier)
        marginInches = defaults.object(forKey: Key.margin) as? Double ?? Double(PaperChoice.defaultMarginInches)
        printerName = defaults.string(forKey: Key.printer) ?? ""
        printerURL = defaults.url(forKey: Key.printerURL)
    }

    var page: PageGeometry { paper.geometry(marginInches: CGFloat(marginInches)) }

    var paperName: String { paper.title }

    /// Shows the system printer picker and remembers the printer chosen.
    func choosePrinter() {
        let picker = UIPrinterPickerController(initiallySelectedPrinter: printerURL.map(UIPrinter.init(url:)))
        picker.present(animated: true) { [weak self] picker, chosen, _ in
            guard chosen, let printer = picker.selectedPrinter else { return }
            MainActor.assumeIsolated { self?.remember(printer) }
        }
    }

    func printTiles(_ data: Data, title: String) {
        TilePrinter.print(data, title: title, paperSize: paper.size, printerURL: printerURL)
    }

    private func remember(_ printer: UIPrinter) {
        printerName = printer.displayName
        printerURL = printer.url
        defaults.set(printerName, forKey: Key.printer)
        defaults.set(printerURL, forKey: Key.printerURL)
    }
}

/// The supplies of a printer, which AirPrint doesn't list; the ink settings start from the standard four inks.
enum PrinterSupplies {
    static func list(for printerName: String) -> [PrinterSupply] { [] }
}
#endif
