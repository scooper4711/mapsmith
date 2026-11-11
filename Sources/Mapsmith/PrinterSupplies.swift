import CUPS
import MapsmithCore

/// Reads the supplies a printer reports to CUPS. Only their names, colors and types: never their levels.
enum PrinterSupplies {
    /// The supplies of the printer with this name, as `NSPrinter` shows it; empty when CUPS has none.
    static func list(for printerName: String) -> [PrinterSupply] {
        var destinations: UnsafeMutablePointer<cups_dest_t>?
        let count = cupsGetDests2(nil, &destinations)
        defer { cupsFreeDests(count, destinations) }
        guard let destinations else { return [] }
        let all = UnsafeBufferPointer(start: destinations, count: Int(count))
        guard let destination = all.first(where: { matches($0, printerName) }) else { return [] }
        return PrinterSupply.list(names: option("marker-names", of: destination),
                                  colors: option("marker-colors", of: destination),
                                  types: option("marker-types", of: destination))
    }

    /// AppKit names a printer by its description (`printer-info`); CUPS by its queue name.
    private static func matches(_ destination: cups_dest_t, _ printerName: String) -> Bool {
        String(cString: destination.name) == printerName || option("printer-info", of: destination) == printerName
    }

    private static func option(_ name: String, of destination: cups_dest_t) -> String {
        cupsGetOption(name, destination.num_options, destination.options).map { String(cString: $0) } ?? ""
    }
}
