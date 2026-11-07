import Foundation
import Security

/// Scrollkeeper's folder in the Tableside Toolkit's App Group,
/// `~/Library/Group Containers/<team ID>.io.github.scooper4711.tableside/Scrollkeeper`, which holds its downloads,
/// cover artwork and `library.json`. Mapsmith only reads it.
public enum ScrollkeeperFolder {
    /// The group's name after the team ID. The team ID isn't committed: `scripts/build-app.sh` fills it in.
    static let groupSuffix = ".io.github.scooper4711.tableside"

    /// The folder, or nil when Mapsmith isn't signed into the group: an ad hoc development build, or a run outside
    /// an app bundle such as the tests.
    public static func url() -> URL? {
        guard let group = tablesideGroup(in: signedGroups()),
              let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group)
        else { return nil }
        return container.appending(path: "Scrollkeeper", directoryHint: .isDirectory)
    }

    /// The toolkit's group among those the app is signed with.
    static func tablesideGroup(in groups: [String]) -> String? {
        groups.first { $0.hasSuffix(groupSuffix) }
    }

    /// The App Groups in the app's own entitlements, which name the team the app was signed by.
    private static func signedGroups() -> [String] {
        guard let task = SecTaskCreateFromSelf(nil),
              let value = SecTaskCopyValueForEntitlement(task, "com.apple.security.application-groups" as CFString, nil)
        else { return [] }
        return value as? [String] ?? []
    }
}
