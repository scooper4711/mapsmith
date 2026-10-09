import AppKit
import MapsmithCore
import Observation

/// Where the print scale (map pixels per inch) came from.
enum ScaleSource: Equatable {
    case detected(CGFloat)
    case fallback(CGFloat, description: String, reason: String)
    case unavailable(reason: String)

    var pixelsPerInch: CGFloat? {
        switch self {
        case .detected(let value), .fallback(let value, _, _): return value
        case .unavailable: return nil
        }
    }
}

/// One window's state: the open file, its maps, the selected map and its tile plan.
@MainActor @Observable
final class AppModel {
    private(set) var fileURL: URL?
    private(set) var items: [MapItem] = []
    private(set) var thumbnails: [UUID: CGImage] = [:]
    var selectedItemID: UUID? { didSet { if selectedItemID != oldValue { loadSelectedMap() } } }

    private(set) var loadedMap: LoadedMap?
    private(set) var preview: CGImage?
    private(set) var scaleSource: ScaleSource?
    private(set) var isBusy = false
    var errorMessage: String?

    /// User-entered pixels per inch; overrides detection when set.
    var manualPixelsPerInch: Double?
    var minimumSliverInches: Double = 0.5

    /// Each window has its own page setup, starting from the one most recently chosen in any window.
    let printInfo = NSPrintInfo.shared.copy() as? NSPrintInfo ?? .shared
    private(set) var page: PageGeometry = .a4Default
    private var loadTask: Task<Void, Never>?

    init() { page = PrintSetup.geometry(of: printInfo) }

    var selectedItem: MapItem? { items.first { $0.id == selectedItemID } }

    var pixelsPerInch: CGFloat? {
        manualPixelsPerInch.map { CGFloat($0) } ?? scaleSource?.pixelsPerInch
    }

    var plan: TilePlan? {
        guard let map = loadedMap, let ppi = pixelsPerInch, ppi > 0 else { return nil }
        let settings = TileSettings(page: page, minimumSliverInches: CGFloat(minimumSliverInches))
        return TilePlanner.plan(mapSize: CGSize(width: map.image.width, height: map.image.height),
                                pixelsPerInch: ppi, settings: settings)
    }

    var printerName: String { PrintSetup.printerName(of: printInfo) }
    var paperName: String { PrintSetup.paperName(of: printInfo) }

    // MARK: - Opening files

    func open(_ url: URL) {
        do {
            let found = try MapItem.items(in: url)
            fileURL = url
            items = found
            thumbnails = [:]
            selectedItemID = found.count == 1 ? found[0].id : nil
            if found.count != 1 { clearSelection() }
            loadThumbnails(for: found)
        } catch {
            errorMessage = "\(error)"
        }
    }

    private func loadThumbnails(for items: [MapItem]) {
        for item in items {
            Task.detached(priority: .utility) { [weak self] in
                let image = try? MapLoader.thumbnail(item.source, maximumSize: 320)
                await MainActor.run { if let image { self?.thumbnails[item.id] = image } }
            }
        }
    }

    // MARK: - Selecting a map

    private func clearSelection() {
        loadTask?.cancel()
        loadedMap = nil
        preview = nil
        scaleSource = nil
        manualPixelsPerInch = nil
    }

    private func loadSelectedMap() {
        clearSelection()
        guard let item = selectedItem else { return }
        isBusy = true
        loadTask = Task.detached(priority: .userInitiated) { [weak self] in
            let result = Result { try MapAnalysis.analyse(item.source) }
            await MainActor.run { self?.finishLoading(item.id, result: result) }
        }
    }

    private func finishLoading(_ itemID: UUID, result: Result<MapAnalysis, Error>) {
        guard itemID == selectedItemID else { return }
        isBusy = false
        switch result {
        case .success(let analysis):
            loadedMap = analysis.map
            preview = analysis.preview
            scaleSource = analysis.scale
        case .failure(let error):
            errorMessage = "\(error)"
        }
    }

    // MARK: - Page setup, export and print

    func runPageSetup() {
        guard PrintSetup.runPageSetup(printInfo) else { return }
        page = PrintSetup.geometry(of: printInfo)
        if let chosen = printInfo.copy() as? NSPrintInfo { NSPrintInfo.shared = chosen }
    }

    func exportPDF() {
        guard let map = loadedMap, let plan else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "\(documentTitle) tiles.pdf"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        renderTiles(map: map, plan: plan) { [weak self] data in
            do { try data.write(to: url) } catch { self?.errorMessage = "Export failed: \(error)" }
        }
    }

    func printTiles() {
        guard let map = loadedMap, let plan else { return }
        let title = documentTitle
        let printInfo = self.printInfo
        renderTiles(map: map, plan: plan) { data in
            PrintSetup.printTiles(data, title: title, printInfo: printInfo)
        }
    }

    var documentTitle: String {
        let base = fileURL?.deletingPathExtension().lastPathComponent ?? "Map"
        guard let item = selectedItem, items.count > 1 else { return base }
        return "\(base) \(item.title)"
    }

    private func renderTiles(map: LoadedMap, plan: TilePlan, then finish: @escaping @MainActor (Data) -> Void) {
        isBusy = true
        let page = self.page
        Task.detached(priority: .userInitiated) { [weak self] in
            let result = Result { try TileExporter.pdfData(map: map.image, plan: plan, page: page) }
            await MainActor.run {
                self?.isBusy = false
                switch result {
                case .success(let data): finish(data)
                case .failure(let error): self?.errorMessage = "\(error)"
                }
            }
        }
    }
}
