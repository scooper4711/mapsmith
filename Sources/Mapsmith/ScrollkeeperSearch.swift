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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Open from Scrollkeeper").font(.headline)
            content
            HStack {
                footnote
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Open") { openSelection() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(selection == nil)
            }
        }
        .padding(20)
        .frame(width: 520, height: 460)
        .onAppear { state = library.state() }
    }

    @ViewBuilder private var content: some View {
        switch state {
        case let .loaded(index):
            TextField("Search your maps", text: $query)
                .textFieldStyle(.roundedBorder)
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
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                if !entry.subtitle.isEmpty {
                    Text(entry.subtitle).font(.caption).foregroundStyle(.secondary)
                }
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
        if case let .loaded(index) = state {
            Text("Library as of \(index.generatedAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func openSelection() {
        guard case let .loaded(index) = state,
              let entry = index.titles.first(where: { $0.id == selection }) else { return }
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

    func launch(_ bundleIdentifier: String) {
        guard let app = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else { return }
        NSWorkspace.shared.openApplication(at: app, configuration: .init())
    }
}
