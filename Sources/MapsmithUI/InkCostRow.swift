import MapsmithCore
import SwiftUI

/// The estimated ink cost of the map, shown only when the selected printer's ink prices are complete.
/// The inspector works out the coverage (`AppModel.estimateInk()`); this prices it.
struct InkCostRow: View {
    @Environment(AppModel.self) private var model
    @Environment(InkPriceBook.self) private var book

    var body: some View {
        if let set = book.completeSet(for: model.printerName),
           let estimate = model.inkCoverage, estimate.key == model.inkEstimateKey {
            cost(set.cost(of: estimate.coverage), pages: estimate.pageCount)
        }
    }

    @ViewBuilder private func cost(_ total: Decimal, pages: Int) -> some View {
        let perPage = pages > 0 ? total / Decimal(pages) : 0
        LabeledContent("Ink", value: "about \(Self.whole(total)) (\(Self.cents(perPage)) a page)")
        Text("An estimate from the ink's rated yield. Printers also use ink for cleaning.")
            .font(.caption).foregroundStyle(.secondary)
    }

    private static func whole(_ amount: Decimal) -> String {
        amount.formatted(.currency(code: InkSettingsView.currencyCode).precision(.fractionLength(0)))
    }

    private static func cents(_ amount: Decimal) -> String {
        amount.formatted(.currency(code: InkSettingsView.currencyCode).precision(.fractionLength(2)))
    }
}
