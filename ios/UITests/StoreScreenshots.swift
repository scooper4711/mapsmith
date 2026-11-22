import XCTest

/// The App Store's pictures, from the app's demo content: tabletop-kit's `store-screenshots.sh`.
/// Skipped unless the script names the folder to save into.
final class StoreScreenshots: XCTestCase {
    private var app: XCUIApplication!
    private var folder: URL!

    override func setUpWithError() throws {
        let path = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] ?? ""
        try XCTSkipIf(path.isEmpty, "Set SCREENSHOT_DIR to make the store screenshots.")
        folder = URL(fileURLWithPath: path)
        continueAfterFailure = false
        app = XCUIApplication()
        XCUIDevice.shared.orientation = .portrait
    }

    @MainActor
    func testMap() throws {
        let map = ProcessInfo.processInfo.environment["STORE_MAP"] ?? ""
        try XCTSkipIf(map.isEmpty, "Set STORE_MAP to the map to show.")
        app.launchEnvironment["UITestSampleFile"] = map
        app.launchArguments = ["-AppleLocale", "en_US", "-AppleLanguages", "(en)"]
        app.launch()
        XCTAssertTrue(app.buttons["Print"].firstMatch.waitForExistence(timeout: 30), app.debugDescription)
        Thread.sleep(forTimeInterval: 3)
        try save("1-map")
    }

    private func save(_ name: String) throws {
        Thread.sleep(forTimeInterval: 1.5)
        let file = folder.appendingPathComponent("\(name).png")
        try XCUIScreen.main.screenshot().pngRepresentation.write(to: file)
    }
}
