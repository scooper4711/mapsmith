#if os(macOS)
import SwiftUI
import TablesideShared

/// File ▸ Open from Scrollkeeper…: the browser in a window of its own.
struct ScrollkeeperWindow: View {
    static let id = "scrollkeeper"

    let bridge: ScrollkeeperBridge
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        ScrollkeeperBrowser(bridge: bridge) { dismissWindow(id: Self.id) }
            .frame(width: 520, height: 460)
            // The status links Scrollkeeper sends arrive as open events. Taking them here keeps this
            // window in front; otherwise SwiftUI hands them to a document window and brings that forward.
            .handlesExternalEvents(preferring: ["*"], allowing: ["*"])
    }
}
#endif
