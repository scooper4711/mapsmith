import AppKit
import MapsmithCore
import SwiftUI

/// File ▸ Open from Scrollkeeper…: search the maps the user owns and ask Scrollkeeper for one.
struct ScrollkeeperSearchSheet: View {
    let library: ScrollkeeperLibrary
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var state = ScrollkeeperLibrary.State.noCatalog
    @State private var query = ""
    @State private var selection: ScrollkeeperMapIndex.Entry.ID?
    @State private var pending = PendingDownloads()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Open from Scrollkeeper").font(.headline)
            content
            HStack {
                footnote
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(selectedEntry?.needsDownload == true ? "Download and Open" : "Open") { openSelection() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(selectedEntry == nil)
            }
        }
        .padding(20)
        .frame(width: 520, height: 460)
        .onAppear { state = library.state() }
        .task(id: pending) { await watchPendingDownloads() }
    }

    private var loadedIndex: ScrollkeeperMapIndex? {
        if case let .loaded(index) = state { index } else { nil }
    }

    private var selectedEntry: ScrollkeeperMapIndex.Entry? {
        loadedIndex?.titles.first { $0.id == selection }
    }

    /// Rereads the map list while downloads started here are running, so their cloud icons go
    /// away as Scrollkeeper finishes them.
    private func watchPendingDownloads() async {
        while !pending.isEmpty, !Task.isCancelled {
            try? await Task.sleep(for: .seconds(1))
            state = library.state()
            if let index = loadedIndex { pending.settle(with: index) }
        }
    }

    @ViewBuilder private var content: some View {
        switch state {
        case let .loaded(index):
            TextField("Search your maps", text: $query)
                .textFieldStyle(.roundedBorder)
                // The best match is chosen as the user types, so Return opens it.
                .onChange(of: query, initial: true) { selection = index.search(query).first?.id }
            results(index.search(query))
        case .notInstalled:
            unavailable("Scrollkeeper Isn't Installed", symbol: "books.vertical",
                        message: "Scrollkeeper downloads the maps you own on paizo.com.") {
                Button("Get Scrollkeeper") { openURL(ScrollkeeperLibrary.downloadPage) }
            }
        case .noCatalog:
            unavailable("No Library Yet", symbol: "person.crop.circle.badge.questionmark",
                        message: "Open Scrollkeeper and sign in to load your library, then try again.") {
                Button("Open Scrollkeeper") { library.launch() }
            }
        case .unsupportedVersion:
            unavailable("Update Mapsmith", symbol: "arrow.down.circle",
                        message: "Scrollkeeper's list of maps is newer than this version of Mapsmith understands.") {
                EmptyView()
            }
        }
    }

    private func results(_ entries: [ScrollkeeperMapIndex.Entry]) -> some View {
        List(entries, selection: $selection) { entry in
            HStack {
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
        .contextMenu(forSelectionType: ScrollkeeperMapIndex.Entry.ID.self) { _ in
        } primaryAction: { chosen in
            selection = chosen.first
            openSelection()
        }
        .overlay {
            if entries.isEmpty { ContentUnavailableView.search(text: query) }
        }
    }

    /// A cloud for titles not on disk yet, which downloads without opening; a spinner while that runs.
    @ViewBuilder private func downloadStatus(of entry: ScrollkeeperMapIndex.Entry) -> some View {
        if pending.contains(entry) {
            ProgressView().controlSize(.small)
                .help("Scrollkeeper is downloading this map")
        } else if entry.needsDownload {
            Button("Download", systemImage: "icloud.and.arrow.down") {
                pending.insert(entry)
                library.download(entry)
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
            .help("Not downloaded yet. Click to download it now, or choose Download and Open.")
        }
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
        if let index = loadedIndex {
            Text("Library as of \(index.generatedAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func openSelection() {
        guard let entry = selectedEntry else { return }
        library.open(entry)
        dismiss()
    }
}

/// The system side of `ApplicationLauncher`.
struct WorkspaceLauncher: ApplicationLauncher {
    func isInstalled(_ bundleIdentifier: String) -> Bool {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) != nil
    }

    func open(_ url: URL) {
        NSWorkspace.shared.open(url)
    }

    func openInBackground(_ url: URL) {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = false
        NSWorkspace.shared.open(url, configuration: configuration)
    }

    func launch(_ bundleIdentifier: String) {
        guard let app = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else { return }
        NSWorkspace.shared.openApplication(at: app, configuration: .init())
    }
}
