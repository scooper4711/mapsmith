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
                TextField("Pixels per square", value: $model.manualPixelsPerInch,
                          format: .number.precision(.fractionLength(0...2)),
                          prompt: Text(model.scaleSource?.pixelsPerInch.map { String(format: "%.1f", $0) } ?? "e.g. 300"))
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

    private func inches(_ size: CGSize) -> String {
        String(format: "%.2f × %.2f in", size.width, size.height)
    }
}
