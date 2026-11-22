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
        try launchMap(arguments: ["-AppleLocale", "en_US"])
        try save("1-map")
    }

    /// The map printed on A3 with the ink it needs: the inspector scrolled down to the result. The iPhone shows the
    /// inspector over the map, so it is opened first.
    @MainActor
    func testMapOnA3() throws {
        try launchMap(arguments: Self.canonSetup)
        if UIDevice.current.userInterfaceIdiom == .phone { app.buttons["Settings"].firstMatch.tap() }
        let printedSize = app.staticTexts["Printed size"].firstMatch
        // The inspector's list builds its rows as they scroll into view.
        for _ in 0..<8 where !printedSize.exists { app.swipeUp() }
        XCTAssertTrue(printedSize.waitForExistence(timeout: 10), app.debugDescription)
        printedSize.swipeUp()
        try save("2-a3-ink")
    }

    /// What the printer's cartridges cost and yield, from Canon's own price list and specifications.
    @MainActor
    func testInkPrices() throws {
        try launchMap(arguments: Self.canonSetup)
        app.buttons["Ink Prices"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Ink Prices"].waitForExistence(timeout: 10), app.debugDescription)
        try save("3-ink-prices")
    }

    private func launchMap(arguments: [String]) throws {
        let map = ProcessInfo.processInfo.environment["STORE_MAP"] ?? ""
        try XCTSkipIf(map.isEmpty, "Set STORE_MAP to the map to show.")
        app.launchEnvironment["UITestSampleFile"] = map
        app.launchArguments = ["-AppleLanguages", "(en)"] + arguments
        app.launch()
        XCTAssertTrue(app.buttons["Print"].firstMatch.waitForExistence(timeout: 30), app.debugDescription)
        Thread.sleep(forTimeInterval: 3)
    }

    private static let printer = "Canon PIXMA TS9500 series"

    /// A3 paper, a Canon PIXMA TS9500 series and its cartridges, in Norwegian kroner: the prices are from Canon
    /// Norge's store (canon.no, standard sizes) and the yields from Canon's specifications (ISO/IEC 24711, A4
    /// color documents). The photo black isn't used for maps.
    private static var canonSetup: [String] {
        let cartridges = [
            ("Magenta", "magenta", 160, 237), ("Black(BK)", "unused", 0, 0), ("Yellow", "yellow", 160, 257),
            ("Black(PGBK)", "black", 170, 200), ("Cyan", "cyan", 160, 256),
        ].map { #"{"name":"\#($0.0)","ink":"\#($0.1)","price":\#($0.2),"ratedPages":\#($0.3)}"# }
        let json = #"{"cartridges":[\#(cartridges.joined(separator: ","))]}"#
        let hex = json.utf8.map { String(format: "%02x", $0) }.joined()
        return ["-AppleLocale", "en_NO", "-PaperChoice", "a3", "-InkPrinterName", printer,
                "-inkSet.\(printer)", "<\(hex)>"]
    }

    private func save(_ name: String) throws {
        Thread.sleep(forTimeInterval: 1.5)
        let file = folder.appendingPathComponent("\(name).png")
        try XCUIScreen.main.screenshot().pngRepresentation.write(to: file)
    }
}
