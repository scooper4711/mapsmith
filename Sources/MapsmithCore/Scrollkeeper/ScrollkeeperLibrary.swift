import Foundation

/// What Mapsmith needs from the system to work with another app. The app uses `NSWorkspace`;
/// tests use a fake.
@MainActor
public protocol ApplicationLauncher {
    func isInstalled(_ bundleIdentifier: String) -> Bool
    func open(_ url: URL)
    /// Opens the URL without bringing its app to the front.
    func openInBackground(_ url: URL)
    func launch(_ bundleIdentifier: String)
}

/// Scrollkeeper as Mapsmith sees it: its list of maps and the requests that ask it to open one.
@MainActor
public struct ScrollkeeperLibrary {
    /// Whether the map list can be shown, and why not when it cannot.
    public enum State: Equatable, Sendable {
        case notInstalled
        case noCatalog
        case unsupportedVersion
        case loaded(ScrollkeeperMapIndex)
    }

    public static let bundleIdentifier = "io.github.scooper4711.Scrollkeeper"
    public static let downloadPage = URL(string: "https://github.com/scooper4711/scrollkeeper/releases/latest")!

    /// Where Scrollkeeper writes the map list. If the apps are ever sandboxed this moves to a
    /// shared App Group container; see the design document.
    public static var defaultIndexURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appending(path: "Library/Application Support/Scrollkeeper/Shared/maps.json")
    }

    private let launcher: ApplicationLauncher
    private let indexURL: URL

    public init(launcher: ApplicationLauncher, indexURL: URL = defaultIndexURL) {
        self.launcher = launcher
        self.indexURL = indexURL
    }

    /// Reads the map list afresh.
    public func state() -> State {
        guard launcher.isInstalled(Self.bundleIdentifier) else { return .notInstalled }
        guard let data = try? Data(contentsOf: indexURL),
              let header = try? Self.decoder.decode(FormatHeader.self, from: data) else { return .noCatalog }
        guard header.formatVersion <= ScrollkeeperMapIndex.supportedFormatVersion else { return .unsupportedVersion }
        guard let index = try? Self.decoder.decode(ScrollkeeperMapIndex.self, from: data) else { return .noCatalog }
        return .loaded(index)
    }

    /// Asks Scrollkeeper to download the title when needed and open it in Mapsmith.
    public func open(_ entry: ScrollkeeperMapIndex.Entry) {
        launcher.open(Self.requestURL(.open, sku: entry.sku))
    }

    /// Asks Scrollkeeper, staying in the background, to download the title without opening it.
    /// The map list says when it is done.
    public func download(_ entry: ScrollkeeperMapIndex.Entry) {
        launcher.openInBackground(Self.requestURL(.download, sku: entry.sku))
    }

    /// Brings Scrollkeeper forward, so the user can sign in and load their library.
    public func launch() {
        launcher.launch(Self.bundleIdentifier)
    }

    /// What Scrollkeeper is asked to do; the host of the request URL.
    enum Request: String {
        case open
        case download
    }

    static func requestURL(_ request: Request, sku: String) -> URL {
        var components = URLComponents()
        components.scheme = "scrollkeeper"
        components.host = request.rawValue
        components.queryItems = [URLQueryItem(name: "sku", value: sku), URLQueryItem(name: "app", value: "mapsmith")]
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
