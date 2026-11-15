import SwiftUI
import TablesideShared

/// Open from Scrollkeeper…: search the maps the user owns and open one, asking Scrollkeeper for it when needed.
/// The Mac shows it in a window of its own, the iPad in a sheet.
struct ScrollkeeperBrowser: View {
    let bridge: ScrollkeeperBridge
    /// Closes the window or sheet.
    let close: () -> Void
    @Environment(\.openURL) private var openURL
    @State private var query = ""
    @State private var selection: ScrollkeeperIndex.Entry.ID?
    /// Set when Scrollkeeper takes a while to answer, so the window can say what may be wrong.
    @State private var isSlow = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
            HStack {
                footnote
                Spacer()
                Button("Cancel", role: .cancel, action: close)
                    .keyboardShortcut(.cancelAction)
                Button(openTitle) { openSelection() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(selectedEntry == nil)
            }
        }
        .padding(20)
        .onAppear(perform: bridge.requestIndex)
        .onChange(of: isOpening) { if isOpening { close() } }
        .task(id: bridge.state) {
            isSlow = false
            guard bridge.state == .waiting else { return }
            try? await Task.sleep(for: .seconds(15))
            isSlow = !Task.isCancelled
        }
    }

    /// Download and Open for a title not on disk, or where Scrollkeeper takes no requests, a way to it.
    private var openTitle: String {
        guard selectedEntry?.downloaded == false else { return "Open" }
        return bridge.takesRequests ? "Download and Open" : "Download in Scrollkeeper"
    }

    private var loadedIndex: ScrollkeeperIndex? {
        if case let .loaded(index) = bridge.state { index } else { nil }
    }

    private var selectedEntry: ScrollkeeperIndex.Entry? {
        loadedIndex?.titles.first { $0.id == selection }
    }

    /// True once a title asked to open is downloaded and its files are on their way.
    private var isOpening: Bool {
        bridge.requests.values.contains { $0.opens && $0.phase == .done }
    }

    @ViewBuilder private var content: some View {
        switch bridge.state {
        case let .loaded(index):
            TextField("Search your maps", text: $query)
                .textFieldStyle(.roundedBorder)
                // The best match is chosen as the user types, so Return opens it.
                .onChange(of: query, initial: true) { selection = index.search(query).first?.id }
            results(index.search(query))
        case .idle, .waiting:
            waiting
        case .notInstalled:
            unavailable("Scrollkeeper Isn't Installed", symbol: "books.vertical",
                        message: "Scrollkeeper downloads the maps you own on paizo.com.") {
                Button("Get Scrollkeeper") { openURL(ScrollkeeperBridge.downloadPage) }
            }
        case .noSharedLibrary:
            unavailable("No Maps from Scrollkeeper Yet", symbol: "books.vertical",
                        message: "Open Scrollkeeper and sign in to paizo.com; your maps then show up here.") {
                Button("Open Scrollkeeper", action: bridge.launchScrollkeeper)
            }
        case .unsupportedVersion:
            unavailable("Update Mapsmith", symbol: "arrow.down.circle",
                        message: "Scrollkeeper's list of maps is newer than this version of Mapsmith understands.") {
                EmptyView()
            }
        case .unreadable:
            unavailable("Couldn't Read the List", symbol: "exclamationmark.triangle",
                        message: "Scrollkeeper's list of maps couldn't be read. Try again.") {
                Button("Try Again", action: bridge.requestIndex)
            }
        case let .failed(reason):
            unavailable("Scrollkeeper Couldn't Send Your Maps", symbol: "exclamationmark.triangle",
                        message: reason) {
                Button("Open Scrollkeeper", action: bridge.launchScrollkeeper)
                Button("Try Again", action: bridge.requestIndex)
            }
        }
    }

    @ViewBuilder private var waiting: some View {
        if isSlow {
            unavailable("Scrollkeeper Hasn't Answered", symbol: "hourglass",
                        message: "Scrollkeeper may still be loading, or need you to sign in.") {
                Button("Open Scrollkeeper", action: bridge.launchScrollkeeper)
                Button("Try Again", action: bridge.requestIndex)
            }
        } else {
            VStack(spacing: 10) {
                ProgressView()
                Text("Asking Scrollkeeper for your maps…").foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func results(_ entries: [ScrollkeeperIndex.Entry]) -> some View {
        List(entries, selection: $selection) { entry in
            HStack {
                ScrollkeeperCoverThumbnail(url: entry.coverURL, placeholderSymbol: "map")
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.title)
                    if !entry.subtitle.isEmpty {
                        Text(entry.subtitle).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                downloadStatus(of: entry)
            }
            .tag(entry.id)
        }
        .contextMenu(forSelectionType: ScrollkeeperIndex.Entry.ID.self) { _ in
        } primaryAction: { chosen in
            selection = chosen.first
            openSelection()
        }
        .overlay {
            if entries.isEmpty { ContentUnavailableView.search(text: query) }
        }
    }

    /// The progress of a title being downloaded, or for one not on disk yet a cloud, which downloads
    /// without opening.
    @ViewBuilder private func downloadStatus(of entry: ScrollkeeperIndex.Entry) -> some View {
        switch bridge.request(for: entry)?.phase {
        case let .downloading(fraction):
            ProgressView(value: fraction).frame(width: 90)
                .help("Scrollkeeper is downloading this map")
        case .requested:
            ProgressView().controlSize(.small)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
        case .done, nil:
            if !entry.downloaded { downloadButton(for: entry) }
        }
    }

    private func downloadButton(for entry: ScrollkeeperIndex.Entry) -> some View {
        Button("Download", systemImage: "icloud.and.arrow.down") { bridge.download(entry) }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
            .help(bridge.takesRequests
                  ? "Not downloaded yet. Click to download it now, or choose Download and Open."
                  : "Not downloaded yet. Click to download it in Scrollkeeper.")
    }

    private func unavailable(_ title: String, symbol: String, message: String,
                             @ViewBuilder action: () -> some View) -> some View {
        ContentUnavailableView {
            Label(title, systemImage: symbol)
        } description: {
            Text(message)
        } actions: {
            action()
        }
        .frame(maxHeight: .infinity)
    }

    @ViewBuilder private var footnote: some View {
        if let request = selectedEntry.flatMap(bridge.request(for:)), let text = Self.describe(request) {
            Text(text)
                .font(.caption)
                .foregroundStyle(request.phase.isFailure ? .red : .secondary)
                .lineLimit(2)
        } else if let index = loadedIndex {
            Text("Library as of \(index.generatedAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private static func describe(_ request: ScrollkeeperRequest) -> String? {
        switch request.phase {
        case .requested: "Asking Scrollkeeper…"
        case let .downloading(fraction): "Scrollkeeper is downloading it: \(Int(fraction * 100))%"
        case .done: request.opens ? "Opening…" : nil
        case let .failed(reason): reason
        }
    }

    /// A map on disk opens at once; for one that needs downloading the window stays to show the progress,
    /// and closes when its files are on their way.
    private func openSelection() {
        guard let entry = selectedEntry else { return }
        bridge.open(entry)
        if entry.downloaded { close() }
    }
}
