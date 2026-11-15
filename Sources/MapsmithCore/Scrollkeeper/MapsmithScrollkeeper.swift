import TablesideShared
import UniformTypeIdentifiers

extension ScrollkeeperBridgeConfiguration {
    /// How Mapsmith uses the Scrollkeeper bridge: it lists the maps, without their kind since every title is one,
    /// opens their PDFs and images, and sends several requests side by side.
    public static var mapsmith: ScrollkeeperBridgeConfiguration {
        var configuration = ScrollkeeperBridgeConfiguration(
            appKey: "mapsmith",
            lists: { $0.kind == mapKind },
            opens: { $0.conforms(to: .pdf) || $0.conforms(to: .image) })
        configuration.showsKind = false
        return configuration
    }

    /// The kind Scrollkeeper gives Flip-Mats, Flip-Tiles, Map Packs, Poster Maps and the like.
    private static let mapKind = "Maps"
}
