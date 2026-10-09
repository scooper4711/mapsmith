import MapsmithCore
import SwiftUI

/// The selected map with the page boundaries it will be printed on.
struct TilePreviewView: View {
    @Environment(AppModel.self) private var model
    @State private var rotatedPreview: (source: CGImage, rotated: CGImage)?

    var body: some View {
        if let preview = model.preview, let plan = model.plan {
            GeometryReader { proxy in
                let image = orientedPreview(preview, rotated: plan.rotated)
                let fitted = fittedSize(CGSize(width: image.width, height: image.height), in: proxy.size)
                ZStack(alignment: .topLeading) {
                    Image(decorative: image, scale: 1).resizable().frame(width: fitted.width, height: fitted.height)
                    TileOverlay(plan: plan, size: fitted)
                }
                .frame(width: fitted.width, height: fitted.height)
                .shadow(radius: 4)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(24)
        } else if model.isBusy {
            ProgressView("Loading map and detecting grid…")
        } else if model.preview != nil {
            ContentUnavailableView(
                "Scale Needed", systemImage: "ruler",
                description: Text("No grid was found. Enter the pixels per grid square in Settings."))
        } else {
            ContentUnavailableView("Select a Map", systemImage: "square.grid.3x3",
                                   description: Text("Pick a map on the left to split it into printer pages."))
        }
    }

    private func orientedPreview(_ preview: CGImage, rotated: Bool) -> CGImage {
        guard rotated else { return preview }
        if let cached = rotatedPreview, cached.source === preview { return cached.rotated }
        let turned = (try? TileExporter.rotatedClockwise(preview)) ?? preview
        DispatchQueue.main.async { rotatedPreview = (preview, turned) }
        return turned
    }

    private func fittedSize(_ size: CGSize, in bounds: CGSize) -> CGSize {
        let factor = min(bounds.width / size.width, bounds.height / size.height)
        return CGSize(width: size.width * factor, height: size.height * factor)
    }
}

/// Outlines and numbers each printer page over the map; shades trimmed edges.
struct TileOverlay: View {
    let plan: TilePlan
    let size: CGSize

    var body: some View {
        let scale = size.width / plan.mapSize.width
        ZStack(alignment: .topLeading) {
            Rectangle().fill(.black.opacity(0.35))
                .mask {
                    Rectangle().overlay(alignment: .topLeading) {
                        ForEach(plan.tiles.indices, id: \.self) { index in
                            Rectangle().frame(width: plan.tiles[index].width * scale,
                                              height: plan.tiles[index].height * scale)
                                .offset(x: plan.tiles[index].minX * scale, y: plan.tiles[index].minY * scale)
                                .blendMode(.destinationOut)
                        }
                    }
                    .compositingGroup()
                }
            ForEach(plan.tiles.indices, id: \.self) { index in
                let tile = plan.tiles[index]
                Rectangle()
                    .strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                    .overlay {
                        Text("\(index + 1)")
                            .font(.title2.bold())
                            .padding(6)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 6))
                    }
                    .frame(width: tile.width * scale, height: tile.height * scale)
                    .offset(x: tile.minX * scale, y: tile.minY * scale)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .allowsHitTesting(false)
    }
}
