import AppKit
import MapsmithCore
import SwiftUI

/// The Ink pane of Settings: what each of a printer's ink cartridges costs and yields.
struct InkSettingsView: View {
    let book: InkPriceBook

    @State private var printer = NSPrintInfo.shared.printer.name
    @State private var draft = InkSet(cartridges: [])

    var body: some View {
        Form {
            Picker("Printer", selection: $printer) {
                ForEach(NSPrinter.printerNames, id: \.self) { Text($0).tag($0) }
            }
            Section {
                ForEach(draft.cartridges.indices, id: \.self) { cartridgeRow($draft.cartridges[$0]) }
            } header: {
                Text("Cartridges")
            } footer: {
                Text("""
                    Enter what one cartridge costs and the number of pages it is rated for. Each cartridge has \
                    its own yield: a black cartridge, a color cartridge and an XL cartridge are rated differently, \
                    so look up every cartridge you use.

                    Find the yield on the ink maker's own web page for your printer or cartridge (look for \
                    "Specifications" or "Supplies"), or on the cartridge's box. Use the standard page yield for \
                    plain-paper documents, measured to ISO/IEC 24711 on A4 pages at 5% coverage. Don't use the \
                    photo yield (for example 4x6 prints), which counts a different, much smaller page. If the \
                    page lists several yields for a cartridge, take the one for text or document pages.

                    These settings only work out the cost estimate. They don't change what the printer prints or \
                    which ink it uses.

                    Choose which ink each cartridge supplies for a map. Some printers have two blacks, such as a \
                    dye black for photos and a pigment black for plain paper; maps use only one, so set the other \
                    to "Exclude from estimate". It then needs no price or yield.

                    If you use third-party cartridges, enter the yield the seller states, or a lower figure if it \
                    states none. They are often cheaper but rated for fewer pages.
                    """)
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 560, height: 600)
        .onChange(of: printer, initial: true) { loadDraft() }
        .onChange(of: draft) { book.save(draft, for: printer) }
    }

    private func cartridgeRow(_ cartridge: Binding<InkCartridge>) -> some View {
        HStack {
            Text(cartridge.wrappedValue.name).frame(maxWidth: .infinity, alignment: .leading)
            Picker("Ink", selection: cartridge.ink) {
                ForEach(InkColor.allCases, id: \.self) { Text($0.title).tag($0) }
            }
            .labelsHidden()
            .frame(width: 140)
            .help("""
                Which ink this cartridge supplies when pricing a map. Choose "Exclude from estimate" for a cartridge \
                the map doesn't use, such as a photo black. It then needs no price or yield. This only affects \
                the cost estimate, not what the printer does.
                """)
            TextField("Price", value: cartridge.price, format: .currency(code: Self.currencyCode))
                .labelsHidden()
                .multilineTextAlignment(.trailing)
                .frame(width: 90)
                .disabled(cartridge.wrappedValue.ink == .unused)
            TextField("Pages", value: cartridge.ratedPages, format: .number)
                .labelsHidden()
                .multilineTextAlignment(.trailing)
                .frame(width: 70)
            Text("pages").foregroundStyle(.secondary)
        }
    }

    private func loadDraft() {
        draft = book.savedSet(for: printer) ?? .defaults(from: PrinterSupplies.list(for: printer))
    }

    static var currencyCode: String { Locale.current.currency?.identifier ?? "USD" }
}

extension InkColor {
    var title: String {
        switch self {
        case .cyan: "Cyan"
        case .magenta: "Magenta"
        case .yellow: "Yellow"
        case .black: "Black"
        case .unused: "Exclude from estimate"
        }
    }
}
