import MapsmithCore
import SwiftUI

#if os(macOS)
import AppKit

/// The inspector's printer and paper, from Page Setup.
struct PrinterSection: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Section("Printer") {
            LabeledContent("Printer", value: model.printerName)
            LabeledContent("Paper", value: model.paperName)
            LabeledContent("Printable area", value: model.page.imageableSizeInches.inchesText)
            Button("Page Setup…") { model.runPageSetup() }
        }
    }
}

/// Settings' printer picker: every printer the Mac knows, starting with the current one.
struct InkPrinterChoice: View {
    static var initialPrinter: String { NSPrintInfo.shared.printer.name }

    @Binding var printer: String

    var body: some View {
        Picker("Printer", selection: $printer) {
            ForEach(NSPrinter.printerNames, id: \.self) { Text($0).tag($0) }
        }
    }
}

#else

/// The inspector's paper and margin, which the iPad has instead of Page Setup, and the printer for ink prices.
struct PrinterSection: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var setup = model.printSetup
        Section {
            Picker("Paper", selection: $setup.paper) {
                ForEach(PaperChoice.allCases) { Text($0.title).tag($0) }
            }
            LabeledNumberField(title: "Margin (in)") {
                TextField("Margin (in)", value: $setup.marginInches, format: .number.precision(.fractionLength(0...3)))
            }
            LabeledContent("Printable area", value: model.page.imageableSizeInches.inchesText)
            LabeledContent("Printer", value: model.printerName.isEmpty ? "None chosen" : model.printerName)
            Button("Choose Printer…") { setup.choosePrinter() }
        } header: {
            Text("Paper")
        } footer: {
            Text("""
                The margin is the border your printer can't print on; ¼ in suits most printers. The printer chosen \
                here is the one the ink prices are for.
                """)
        }
        .onChange(of: setup.paper) { model.refreshPage() }
        .onChange(of: setup.marginInches) { model.refreshPage() }
    }
}

/// The Ink Prices sheet's printer: the one chosen in the inspector.
struct InkPrinterChoice: View {
    @MainActor static var initialPrinter: String { "" }

    @Binding var printer: String
    @Environment(AppModel.self) private var model

    var body: some View {
        Section {
            LabeledContent("Printer", value: model.printerName.isEmpty ? "None chosen" : model.printerName)
            Button("Choose Printer…") { model.printSetup.choosePrinter() }
        }
        .onChange(of: model.printerName, initial: true) { printer = model.printerName }
    }
}
#endif
