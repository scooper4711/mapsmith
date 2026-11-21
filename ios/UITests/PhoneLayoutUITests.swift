import XCTest

/// On an iPhone the window is one screen at a time: it opens on the map, never on the empty list of maps, and the
/// settings stay closed until asked for. Each test keeps a screenshot in the test results.
@MainActor
final class PhoneLayoutUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .phone, "Only an iPhone has one screen at a time.")
        continueAfterFailure = false
        app = XCUIApplication()
    }

    func testTheWindowOpensOnTheWaysIn() {
        app.launch()

        XCTAssertTrue(app.buttons["Open…"].waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertTrue(app.buttons["Open…"].isHittable)
        XCTAssertTrue(app.buttons["Open from Scrollkeeper…"].isHittable)
        XCTAssertFalse(app.staticTexts["Paper"].exists, "The settings cover the window")
        keepScreenshot("iPhone empty window")
    }

    func testAMapShowsItsPagesWithTheSettingsClosed() {
        app.launchArguments = ["-UITestSample"]
        app.launch()

        let lastPage = app.staticTexts["8"]
        XCTAssertTrue(lastPage.waitForExistence(timeout: 20), app.debugDescription)
        XCTAssertTrue(lastPage.isHittable, "The settings cover the pages")
        XCTAssertTrue(app.buttons["Print"].isHittable, "No Print button in the toolbar")
        keepScreenshot("iPhone map")
    }

    private func keepScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
