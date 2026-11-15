import Foundation
import MapsmithCore
import os
import UniformTypeIdentifiers

/// Opens whatever is dropped on a window: files, images dragged straight out of another app
/// (such as a map from Pluck), which arrive as image data rather than as a file, and on the iPad PDFs dragged
/// from Files, which arrive as a copy to take during the drop.
@MainActor
enum MapDrop {
    static let acceptedTypes: [UTType] = [.fileURL, .pdf, .image]

    private nonisolated static let logger = Logger(subsystem: "io.github.scooper4711.Mapsmith", category: "drop")

    static func open(_ providers: [NSItemProvider], with router: DocumentRouter) -> Bool {
        let usable = providers.filter { carriesFile($0) || carriesPDF($0) || imageType(of: $0) != nil }
        for provider in usable {
            // Prefer the original file; use a copy or the image data only when no file is behind the drag.
            if carriesFile(provider) {
                openFile(of: provider, with: router)
            } else if carriesPDF(provider) {
                openPDFCopy(of: provider, with: router)
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

    private static func carriesPDF(_ provider: NSItemProvider) -> Bool {
        provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier)
    }

    /// The file handed over is removed once the drop ends, so it is copied first.
    private static func openPDFCopy(of provider: NSItemProvider, with router: DocumentRouter) {
        let suggestedName = provider.suggestedName
        _ = provider.loadFileRepresentation(for: .pdf) { file, _, error in
            do {
                guard let file else { throw error ?? CocoaError(.fileReadUnknown) }
                let url = try DroppedImageStore.standard.saveCopy(of: file, suggestedName: suggestedName, type: .pdf)
                Task { @MainActor in router.open([url]) }
            } catch {
                logger.error("Opening a dropped PDF failed: \(error.localizedDescription)")
            }
        }
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
