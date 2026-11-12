import AppNotices
import MapsmithCore
import SwiftUI

struct ContentView: View {
    @Environment(AppModel.self) private var model
    @Environment(DocumentRouter.self) private var router
    @State private var showsInspector = true
    @State private var isDropTargeted = false
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        @Bindable var model = model
        NavigationSplitView {
            MapListView()
                .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 360)
        } detail: {
            detail
                .inspector(isPresented: $showsInspector) {
                    SettingsInspector()
                        .inspectorColumnWidth(min: 260, ideal: 280, max: 360)
                }
        }
        .navigationTitle(model.fileURL?.lastPathComponent ?? "Mapsmith")
        .toolbar { toolbar }
        .onDrop(of: MapDrop.acceptedTypes, isTargeted: $isDropTargeted) { providers in
            MapDrop.open(providers, with: router)
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    /// A window with no file shows the two ways in, here only; the sidebar stays an empty list.
    @ViewBuilder private var detail: some View {
        if model.fileURL == nil, !model.isBusy {
            EmptyWindowView(
                title: "Open a Map", symbol: "map", message: "Drop a PDF or an image of a battle map here.",
                isDropTargeted: isDropTargeted, open: { router.open(OpenPanel.chooseFiles()) },
                openFromScrollkeeper: { openWindow(id: ScrollkeeperWindow.id) })
        } else {
            TilePreviewView()
        }
    }

    @ToolbarContentBuilder private var toolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            if model.isBusy { ProgressView().controlSize(.small) }
            Button("Open", systemImage: "folder") { router.open(OpenPanel.chooseFiles()) }
            Button("Export PDF", systemImage: "square.and.arrow.up") { model.exportPDF() }
                .disabled(model.plan == nil || model.isBusy)
            Button("Print", systemImage: "printer") { model.printTiles() }
                .disabled(model.plan == nil || model.isBusy)
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
