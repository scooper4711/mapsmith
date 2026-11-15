import MapsmithCore
import Observation
import os
import UniformTypeIdentifiers
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Backs File ▸ New from Clipboard: knows whether the clipboard holds a map, and opens it like a drop.
///
/// The clipboard is checked when Mapsmith becomes active, since maps are copied in other apps (Pluck, a browser,
/// Preview), and on the iPad also when it changes inside Mapsmith. Checking only looks at the types, so the system
/// asks no paste permission until the command is chosen. Copied files are assumed to be maps until then.
@MainActor @Observable
final class ClipboardWatcher {
    private(set) var hasMap = false
    @ObservationIgnored private var observers: [NSObjectProtocol] = []

    private nonisolated static let logger = Logger(subsystem: "io.github.scooper4711.Mapsmith", category: "clipboard")

    init() {
        refresh()
        observers = Self.changeNotifications.map { name in
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.refresh() }
            }
        }
    }

    func refresh() {
        hasMap = SystemClipboard.content(readingFiles: false) != nil
    }

    /// Opens the copied files, or saves the copied image to the dropped-maps folder and opens that.
    func open(with router: DocumentRouter) {
        do {
            switch SystemClipboard.content(readingFiles: true) {
            case let .files(urls): router.open(urls)
            case let .data(type): router.open([try Self.savePasted(type)])
            case nil: break
            }
        } catch {
            Self.logger.error("New from Clipboard failed: \(error.localizedDescription)")
        }
    }

    private static func savePasted(_ type: UTType) throws -> URL {
        guard let data = SystemClipboard.data(for: type) else { throw CocoaError(.fileReadUnknown) }
        return try DroppedImageStore.standard.save(data, suggestedName: ClipboardMap.defaultName, type: type)
    }

    #if os(macOS)
    private static let changeNotifications = [NSApplication.didBecomeActiveNotification]
    #else
    private static let changeNotifications = [UIApplication.didBecomeActiveNotification,
                                              UIPasteboard.changedNotification]
    #endif
}

/// The system clipboard, read through `ClipboardMap`.
@MainActor
private enum SystemClipboard {
    /// Without `readingFiles` the copied files are only assumed to be maps: reading them can ask the user for
    /// permission, which only choosing the command should do.
    static func content(readingFiles: Bool) -> ClipboardMap? {
        let types = self.types
        guard types.contains(.fileURL) else { return ClipboardMap.content(fileURLs: [], types: types) }
        guard readingFiles else { return .files([]) }
        return ClipboardMap.content(fileURLs: fileURLs, types: types)
    }

    #if os(macOS)
    private static var types: [UTType] {
        (NSPasteboard.general.types ?? []).compactMap { UTType($0.rawValue) }
    }

    private static var fileURLs: [URL] {
        let objects = NSPasteboard.general.readObjects(forClasses: [NSURL.self],
                                                       options: [.urlReadingFileURLsOnly: true])
        return (objects as? [URL]) ?? []
    }

    static func data(for type: UTType) -> Data? {
        NSPasteboard.general.data(forType: NSPasteboard.PasteboardType(type.identifier))
    }
    #else
    private static var types: [UTType] {
        UIPasteboard.general.types.compactMap { UTType($0) }
    }

    private static var fileURLs: [URL] {
        (UIPasteboard.general.urls ?? []).filter(\.isFileURL)
    }

    static func data(for type: UTType) -> Data? {
        UIPasteboard.general.data(forPasteboardType: type.identifier)
    }
    #endif
}
