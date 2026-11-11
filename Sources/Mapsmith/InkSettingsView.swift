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
                    Enter what each cartridge costs and its rated yield in A4 pages (ISO/IEC 24711). The yield is \
                    on the cartridge's box and on the Specifications tab of the printer's page on the maker's \
                    website.
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
        case .unused: "Not used for maps"
        }
    }
}
