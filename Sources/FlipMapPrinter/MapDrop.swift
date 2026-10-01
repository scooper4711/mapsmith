import AppKit
import FlipMapCore
import os
import UniformTypeIdentifiers

/// Opens whatever is dropped on a window: files, or images dragged straight out of another app
/// (such as a map from Pluck), which arrive as image data rather than as a file.
@MainActor
enum MapDrop {
    static let acceptedTypes: [UTType] = [.fileURL, .image]

    private nonisolated static let logger = Logger(subsystem: "com.github.scooper4711.FlipMapPrinter", category: "drop")

    static func open(_ providers: [NSItemProvider], with router: DocumentRouter) -> Bool {
        let usable = providers.filter { carriesFile($0) || imageType(of: $0) != nil }
        for provider in usable {
            // Prefer the original file; use the image data only when no file is behind the drag.
            if carriesFile(provider) {
                openFile(of: provider, with: router)
            } else {
                openImageData(of: provider, with: router)
            }
        }
        return !usable.isEmpty
    }

    /// An exact match, because a promised file (which is not readable yet) has a look-alike type.
    private static func carriesFile(_ provider: NSItemProvider) -> Bool {
        provider.registeredTypeIdentifiers.contains(UTType.fileURL.identifier)
    }

    private static func openFile(of provider: NSItemProvider, with router: DocumentRouter) {
        _ = provider.loadObject(ofClass: URL.self) { url, _ in
            guard let url else { return }
            Task { @MainActor in router.open([url]) }
        }
    }

    private static func openImageData(of provider: NSItemProvider, with router: DocumentRouter) {
        guard let type = imageType(of: provider) else { return }
        let suggestedName = provider.suggestedName
        _ = provider.loadDataRepresentation(for: type) { data, error in
            do {
                guard let data else { throw error ?? CocoaError(.fileReadUnknown) }
                let url = try DroppedImageStore.standard.save(data, suggestedName: suggestedName, type: type)
                Task { @MainActor in router.open([url]) }
            } catch {
                logger.error("Opening a dropped image failed: \(error.localizedDescription)")
            }
        }
    }

    /// PNG when offered, since it is lossless; otherwise the first image type the drag carries.
    private static func imageType(of provider: NSItemProvider) -> UTType? {
        let types = provider.registeredContentTypes(conformingTo: .image)
        return types.contains(.png) ? .png : types.first
    }
}
