import MapsmithCore
import SwiftUI

/// Print settings, map scale and the resulting page count.
struct SettingsInspector: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Form {
            Section("Printer") {
                LabeledContent("Printer", value: model.printerName)
                LabeledContent("Paper", value: model.paperName)
                LabeledContent("Printable area", value: inches(model.page.imageableSizeInches))
                Button("Page Setup…") { model.runPageSetup() }
            }

            Section("Scale") {
                scaleDescription
                if model.loadedMap != nil {
                    LabeledContent("Image size", value: pixels(model.mapPixelSize))
                }
                DeferredNumberField(title: "Pixels per square", value: model.manualPixelsPerInch,
                                    prompt: detectedScale) { model.setScale($0.map(ScaleEntry.pixelsPerSquare)) }
                if model.loadedMap != nil { squareFields }
                if model.manualPixelsPerInch != nil {
                    Button("Use Detected Scale") { model.manualPixelsPerInch = nil }
                }
            }

            Section("Edges") {
                TextField("Skip strips under (in)", value: $model.minimumSliverInches,
                          format: .number.precision(.fractionLength(0...2)))
                Text("An edge row or column holding less map than this is trimmed instead of printed.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            if let plan = model.plan { resultSection(plan) }
        }
        .formStyle(.grouped)
    }

    @ViewBuilder private var scaleDescription: some View {
        switch model.scaleSource {
        case .detected(let ppi)?:
            Label(String(format: "Grid detected: %.1f px per square", ppi), systemImage: "checkmark.circle")
                .foregroundStyle(.green)
        case let .fallback(ppi, description, reason)?:
            Label(String(format: "Using %@: %.1f px per inch", description, ppi),
                  systemImage: "exclamationmark.triangle")
                .foregroundStyle(.orange)
                .help(reason)
        case .unavailable(let reason)?:
            Label("No grid found — enter pixels per square below", systemImage: "xmark.octagon")
                .foregroundStyle(.red)
                .help(reason)
        case nil:
            Text("Select a map").foregroundStyle(.secondary)
        }
    }

    /// The scale as 1-inch squares across and down; the detected count is the placeholder.
    @ViewBuilder private var squareFields: some View {
        let size = model.mapPixelSize
        let entered = model.manualPixelsPerInch.map { ScaleEntry.squares(mapSize: size, pixelsPerInch: $0) }
        let detected = model.scaleSource?.pixelsPerInch.map { ScaleEntry.squares(mapSize: size, pixelsPerInch: $0) }
        DeferredNumberField(title: "Squares across", value: entered.map { Double($0.width) },
                            prompt: count(detected?.width)) { model.setScale($0.map(ScaleEntry.squaresAcross)) }
        DeferredNumberField(title: "Squares down", value: entered.map { Double($0.height) },
                            prompt: count(detected?.height)) { model.setScale($0.map(ScaleEntry.squaresDown)) }
    }

    private func count(_ squares: CGFloat?) -> String {
        squares.map { String(format: "%.1f", $0) } ?? ""
    }

    /// The detected scale, shown as the manual field's placeholder.
    private var detectedScale: String {
        model.scaleSource?.pixelsPerInch.map { String(format: "%.1f", $0) } ?? "e.g. 300"
    }

    private func resultSection(_ plan: TilePlan) -> some View {
        Section("Result") {
            LabeledContent("Pages", value: "\(plan.columns) × \(plan.rows) = \(plan.sheetCount)")
            LabeledContent("Printed size", value: inches(CGSize(width: plan.mapSize.width / plan.pixelsPerInch,
                                                                height: plan.mapSize.height / plan.pixelsPerInch)))
            if plan.rotated {
                Text("Map turned 90° to use fewer pages.").font(.caption).foregroundStyle(.secondary)
            }
            Text("Print at 100% scale. Trim each page's white border where pages meet.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private func pixels(_ size: CGSize) -> String {
        "\(Int(size.width)) × \(Int(size.height)) px"
    }

    private func inches(_ size: CGSize) -> String {
        String(format: "%.2f × %.2f in", size.width, size.height)
    }
}
