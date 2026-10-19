import Foundation
import Observation

/// What Mapsmith needs from the system to work with another app. The app uses `NSWorkspace`;
/// tests use a fake.
@MainActor
public protocol ApplicationLauncher {
    func isInstalled(_ bundleIdentifier: String) -> Bool
    /// Opens the URL without bringing its app to the front.
    func openInBackground(_ url: URL)
    func launch(_ bundleIdentifier: String)
}

/// A title Mapsmith asked Scrollkeeper for, and how that is going.
public struct ScrollkeeperRequest: Equatable, Sendable {
    public enum Phase: Equatable, Sendable {
        case requested
        case downloading(Double)
        /// Downloaded; when the title was asked to open, its files are on their way.
        case done
        case failed(String)
    }

    public var sku: String
    /// True for Open and Download and Open; false when the title is only downloaded.
    public var opens: Bool
    public var phase: Phase
}

/// Scrollkeeper as Mapsmith sees it: Mapsmith asks for the list of maps, Scrollkeeper hands it over
/// as a file, and Mapsmith asks it to download or open a title. Scrollkeeper stays in the background
/// and reports how each request goes with status links.
@MainActor
@Observable
public final class ScrollkeeperBridge {
    public enum State: Equatable, Sendable {
        case idle
        case notInstalled
        /// Asked for the list; Scrollkeeper may still be starting or loading its library.
        case waiting
        case unsupportedVersion
        case unreadable
        /// Scrollkeeper couldn't send the list, for the reason it gives.
        case failed(String)
        case loaded(ScrollkeeperIndex)
    }

    public static let bundleIdentifier = "io.github.scooper4711.Scrollkeeper"
    public static let downloadPage = URL(string: "https://github.com/scooper4711/scrollkeeper/releases/latest")!

    public private(set) var state = State.idle
    /// The requests sent since the list was last asked for, by SKU.
    public private(set) var requests: [String: ScrollkeeperRequest] = [:]
    @ObservationIgnored private let launcher: ApplicationLauncher

    public init(launcher: ApplicationLauncher) {
        self.launcher = launcher
    }

    /// Asks Scrollkeeper, staying in the background, to hand over the list of maps.
    public func requestIndex() {
        requests = [:]
        guard launcher.isInstalled(Self.bundleIdentifier) else {
            state = .notInstalled
            return
        }
        state = .waiting
        launcher.openInBackground(Self.requestURL(host: "index", sku: nil))
    }

    /// Reads the list Scrollkeeper handed over.
    public func receive(_ file: URL) {
        guard let data = try? Data(contentsOf: file),
              let header = try? Self.decoder.decode(FormatHeader.self, from: data) else {
            state = .unreadable
            return
        }
        guard header.formatVersion <= ScrollkeeperIndex.supportedFormatVersion else {
            state = .unsupportedVersion
            return
        }
        guard let index = try? Self.decoder.decode(ScrollkeeperIndex.self, from: data) else {
            state = .unreadable
            return
        }
        state = .loaded(index)
    }

    /// Asks Scrollkeeper to download the title when needed and open it in Mapsmith.
    public func open(_ entry: ScrollkeeperIndex.Entry) {
        send(entry, opens: true)
    }

    /// Asks Scrollkeeper to download the title without opening it.
    public func download(_ entry: ScrollkeeperIndex.Entry) {
        send(entry, opens: false)
    }

    /// The request for the title, if one was sent.
    public func request(for entry: ScrollkeeperIndex.Entry) -> ScrollkeeperRequest? {
        requests[entry.sku]
    }

    /// True for a link in which Scrollkeeper reports how a request is going.
    public static func isStatusLink(_ url: URL) -> Bool {
        url.scheme == statusScheme && url.host == "handoff"
    }

    /// Takes a status link: `mapsmith://handoff?sku=…&state=downloading|done|failed[&fraction=…][&reason=…]`.
    public func receiveStatus(_ url: URL) {
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let value = { (name: String) in items.first { $0.name == name }?.value ?? "" }
        let sku = value("sku")
        if sku.isEmpty, value("state") == "failed" {
            state = .failed(value("reason"))
            return
        }
        guard requests[sku] != nil, let phase = Self.phase(state: value("state"), items: value) else { return }
        requests[sku]?.phase = phase
        if phase == .done { markDownloaded(sku) }
    }

    /// Brings Scrollkeeper forward, so the user can sign in and load their library.
    public func launchScrollkeeper() {
        launcher.launch(Self.bundleIdentifier)
    }

    private func send(_ entry: ScrollkeeperIndex.Entry, opens: Bool) {
        requests[entry.sku] = ScrollkeeperRequest(sku: entry.sku, opens: opens, phase: .requested)
        launcher.openInBackground(Self.requestURL(host: opens ? "open" : "download", sku: entry.sku))
    }

    private func markDownloaded(_ sku: String) {
        guard case var .loaded(index) = state else { return }
        index.markDownloaded(sku)
        state = .loaded(index)
    }

    private static func phase(state: String, items value: (String) -> String) -> ScrollkeeperRequest.Phase? {
        switch state {
        case "downloading": .downloading(Double(value("fraction")) ?? 0)
        case "done": .done
        case "failed": .failed(value("reason"))
        default: nil
        }
    }

    private static let statusScheme = "mapsmith"

    static func requestURL(host: String, sku: String?) -> URL {
        var components = URLComponents()
        components.scheme = "scrollkeeper"
        components.host = host
        components.queryItems = (sku.map { [URLQueryItem(name: "sku", value: $0)] } ?? [])
            + [URLQueryItem(name: "app", value: "mapsmith")]
        return components.url!
    }

    private struct FormatHeader: Decodable {
        var formatVersion: Int
    }

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
