import XCTest

/// The window in both orientations, empty and with a map: what a user sees first, and the map with its pages and
/// the inspector. Each test keeps a screenshot in the test results.
final class LayoutUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() {
        XCUIDevice.shared.orientation = .portrait
        super.tearDown()
    }

    func testEmptyWindowInLandscape() {
        showEmptyWindow(.landscapeLeft)
    }

    func testEmptyWindowInPortrait() {
        showEmptyWindow(.portrait)
    }

    func testMapAndInspectorInLandscape() throws {
        try skipOnAPhone()
        showMap(.landscapeLeft)
    }

    func testMapAndInspectorInPortrait() throws {
        try skipOnAPhone()
        showMap(.portrait)
    }

    func testOpenFromScrollkeeperSaysWhereTheMapsComeFrom() {
        launch(.landscapeLeft)
        app.buttons["Open from Scrollkeeper…"].tap()
        // Unsigned in the simulator, the app has no App Group, so there is no library to show. What it says depends
        // on whether the simulator has Scrollkeeper installed.
        let notice = app.staticTexts.matching(NSPredicate(
            format: "label IN %@", ["Scrollkeeper Isn't Installed", "No Maps from Scrollkeeper Yet"]))
        XCTAssertTrue(notice.firstMatch.waitForExistence(timeout: 10), app.debugDescription)
        keepScreenshot("Open from Scrollkeeper")
    }

    /// An iPhone has no room for the inspector beside the map (PhoneLayoutUITests).
    private func skipOnAPhone() throws {
        try XCTSkipIf(UIDevice.current.userInterfaceIdiom == .phone, "The iPhone shows the settings as a sheet.")
    }

    private func showEmptyWindow(_ orientation: UIDeviceOrientation) {
        launch(orientation)
        XCTAssertTrue(app.buttons["Open…"].waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertTrue(app.buttons["Open…"].isHittable)
        XCTAssertTrue(app.buttons["Open from Scrollkeeper…"].isHittable)
        keepScreenshot("Empty window, \(orientation == .portrait ? "portrait" : "landscape")")
    }

    private func showMap(_ orientation: UIDeviceOrientation) {
        launch(orientation, arguments: ["-UITestSample"])
        // The sample's 100 px squares are found, and the inspector shows the paper and the page count.
        let detected = app.staticTexts["Grid detected: 100.0 px per square"]
        XCTAssertTrue(detected.waitForExistence(timeout: 20), app.debugDescription)
        XCTAssertTrue(app.buttons["Paper"].exists || app.staticTexts["Paper"].exists, app.debugDescription)
        XCTAssertTrue(app.staticTexts["Margin (in)"].exists, app.debugDescription)
        for action in ["Open", "Export PDF", "Print", "Ink Prices"] {
            XCTAssertTrue(app.buttons[action].isHittable, "No \(action) button in the toolbar")
        }
        // Every page is on screen, none under the inspector.
        let lastPage = app.staticTexts["8"]
        XCTAssertTrue(lastPage.exists && lastPage.isHittable, app.debugDescription)
        keepScreenshot("Map and inspector, \(orientation == .portrait ? "portrait" : "landscape")")
    }

    private func launch(_ orientation: UIDeviceOrientation, arguments: [String] = []) {
        XCUIDevice.shared.orientation = orientation
        app.launchArguments = arguments
        app.launch()
    }

    private func keepScreenshot(_ name: String) {
        // Let a rotation finish first. The screen's screenshot, unlike the app's, isn't cropped to portrait.
        Thread.sleep(forTimeInterval: 1)
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
