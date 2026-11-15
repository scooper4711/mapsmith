#if os(macOS)
import AppKit
import MapsmithCore
import SwiftUI

/// File ▸ Open from Scrollkeeper…: the browser in a window of its own.
struct ScrollkeeperWindow: View {
    static let id = "scrollkeeper"

    let bridge: ScrollkeeperBridge
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        ScrollkeeperBrowser(bridge: bridge) { dismissWindow(id: Self.id) }
            .frame(width: 520, height: 460)
            // The list and status links Scrollkeeper sends arrive as open events. Taking them here keeps this
            // window in front; otherwise SwiftUI hands them to a document window and brings that forward.
            .handlesExternalEvents(preferring: ["*"], allowing: ["*"])
    }
}

/// The system side of `ApplicationLauncher`. Scrollkeeper on the Mac answers requests.
struct WorkspaceLauncher: ApplicationLauncher {
    var takesRequests: Bool { true }

    func isInstalled(_ bundleIdentifier: String) -> Bool {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) != nil
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
#endif
