import AppNotices
import MapsmithCore
import SwiftUI

/// The ways in and out the window has, which each platform supplies: the Mac with its panels and windows, the iPad
/// with sheets.
struct DocumentActions {
    var open: () -> Void = {}
    var openFromScrollkeeper: () -> Void = {}
    /// Ink prices; on the Mac they are in Settings, so this is nil there.
    var showInkPrices: (() -> Void)?
    /// The About screen; on the Mac it is in the app menu, so this is nil there.
    var showAbout: (() -> Void)?
}

extension EnvironmentValues {
    @Entry var documentActions = DocumentActions()
}

struct ContentView: View {
    @Environment(AppModel.self) private var model
    @Environment(DocumentRouter.self) private var router
    @Environment(\.documentActions) private var actions
    @State private var showsInspector = true
    @State private var isDropTargeted = false
    @State private var columns = NavigationSplitViewVisibility.automatic
    /// The screen an iPhone opens on. Its width holds one column, and the list of maps is empty until a file is
    /// open, so starting there would show a blank screen.
    @State private var compactColumn = NavigationSplitViewColumn.detail
    #if os(iOS)
    /// Read here, outside the split view, whose columns are compact on the iPad too.
    @Environment(\.horizontalSizeClass) private var sizeClass
    #endif

    var body: some View {
        @Bindable var model = model
        NavigationSplitView(columnVisibility: $columns, preferredCompactColumn: $compactColumn) {
            MapListView()
                .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 360)
        } detail: {
            detail
                // On the detail column rather than the split view, where the iPad shows no toolbar.
                .toolbar { toolbar }
                .navigationTitle(model.fileURL?.lastPathComponent ?? "Mapsmith")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                // An iPhone's way back to the list of maps, which has nothing to choose with fewer than two.
                .navigationBarBackButtonHidden(model.items.count < 2)
                #endif
                .inspector(isPresented: $showsInspector) {
                    SettingsInspector()
                        .inspectorColumnWidth(min: 260, ideal: 280, max: 360)
                }
        }
        #if os(iOS)
        // The iPad has less room: an image or a one-map PDF has nothing to choose in the list, so the map gets it.
        .onChange(of: model.items.count, initial: true) {
            columns = model.items.count > 1 ? .automatic : .detailOnly
        }
        // An iPhone shows the map that was chosen in the list.
        .onChange(of: model.selectedItemID) { compactColumn = .detail }
        // On an iPhone the settings are a sheet over the whole window, so they wait to be asked for.
        .onChange(of: sizeClass, initial: true) {
            if sizeClass == .compact { showsInspector = false }
        }
        #endif
        .onDrop(of: MapDrop.acceptedTypes, isTargeted: $isDropTargeted) { providers in
            MapDrop.open(providers, with: router)
        }
        .fileExporter(isPresented: isExporting, document: model.exportedTiles, contentType: .pdf,
                      defaultFilename: model.exportedTiles?.name) { result in
            if case let .failure(error) = result { model.errorMessage = "Export failed: \(error.localizedDescription)" }
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    private var isExporting: Binding<Bool> {
        Binding(get: { model.exportedTiles != nil }, set: { if !$0 { model.exportedTiles = nil } })
    }

    /// A window with no file shows the two ways in, here only; the sidebar stays an empty list.
    @ViewBuilder private var detail: some View {
        if model.fileURL == nil, !model.isBusy {
            EmptyWindowView(
                title: "Open a Map", symbol: "map", message: "Drop a PDF or an image of a battle map here.",
                isDropTargeted: isDropTargeted, open: actions.open,
                openFromScrollkeeper: actions.openFromScrollkeeper)
        } else {
            TilePreviewView()
        }
    }

    @ToolbarContentBuilder private var toolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            if model.isBusy { ProgressView().controlSize(.small) }
            Button("Open", systemImage: "folder", action: actions.open)
            Button("Export PDF", systemImage: "square.and.arrow.up") { model.exportPDF() }
                .disabled(model.plan == nil || model.isBusy)
            Button("Print", systemImage: "printer") { model.printTiles() }
                .disabled(model.plan == nil || model.isBusy)
            if let showInkPrices = actions.showInkPrices {
                Button("Ink Prices", systemImage: "drop", action: showInkPrices)
            }
            if let showAbout = actions.showAbout {
                Button("About", systemImage: "info.circle", action: showAbout)
            }
            Button("Settings", systemImage: "sidebar.right") { showsInspector.toggle() }
        }
    }
}

/// Sidebar: a thumbnail for every map in the open file.
struct MapListView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        List(model.items, selection: $model.selectedItemID) { item in
            VStack(alignment: .leading, spacing: 6) {
                thumbnail(for: item)
                Text(item.title).font(.callout)
            }
            .padding(.vertical, 4)
            .tag(item.id)
        }
    }

    @ViewBuilder private func thumbnail(for item: MapItem) -> some View {
        if let image = model.thumbnails[item.id] {
            Image(decorative: image, scale: 1)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 200)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        } else {
            RoundedRectangle(cornerRadius: 4)
                .fill(.quaternary)
                .frame(height: 140)
                .overlay { ProgressView().controlSize(.small) }
        }
    }
}
