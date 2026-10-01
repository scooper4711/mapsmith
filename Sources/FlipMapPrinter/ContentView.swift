import FlipMapCore
import SwiftUI

struct ContentView: View {
    @Environment(AppModel.self) private var model
    @Environment(DocumentRouter.self) private var router
    @State private var showsInspector = true

    var body: some View {
        @Bindable var model = model
        NavigationSplitView {
            MapListView()
                .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 360)
        } detail: {
            TilePreviewView()
                .inspector(isPresented: $showsInspector) {
                    SettingsInspector()
                        .inspectorColumnWidth(min: 260, ideal: 280, max: 360)
                }
        }
        .navigationTitle(model.fileURL?.lastPathComponent ?? "Flip Map Printer")
        .toolbar { toolbar }
        .dropDestination(for: URL.self) { urls, _ in
            router.open(urls)
            return !urls.isEmpty
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(model.errorMessage ?? "")
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
        if model.items.isEmpty {
            ContentUnavailableView("No File Open", systemImage: "map",
                                   description: Text("Open or drop a PDF or image of a battle map."))
        } else {
            List(model.items, selection: $model.selectedItemID) { item in
                VStack(alignment: .leading, spacing: 6) {
                    thumbnail(for: item)
                    Text(item.title).font(.callout)
                }
                .padding(.vertical, 4)
                .tag(item.id)
            }
        }
    }

    @ViewBuilder private func thumbnail(for item: MapItem) -> some View {
        if let image = model.thumbnails[item.id] {
            Image(decorative: image, scale: 1)
                .resizable()
                .aspectRatio(contentMode: .fit)
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
