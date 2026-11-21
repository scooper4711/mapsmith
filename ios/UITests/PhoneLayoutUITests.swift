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

    func testAFileOfSeveralMapsOpensOnItsFirst() {
        app.launchArguments = ["-UITestSamplePDF"]
        app.launch()

        XCTAssertTrue(waitForAMap(), "No map was chosen when the file opened\n\(app.debugDescription)")
        XCTAssertFalse(app.staticTexts["Select a Map"].exists)
        keepScreenshot("iPhone first map of two")
    }

    func testTheListOfMapsShowsTheOneChosen() {
        app.launchArguments = ["-UITestSamplePDF"]
        app.launch()
        XCTAssertTrue(waitForAMap(), app.debugDescription)

        // Found by its identifier: not every iPhone puts the toolbar in a navigation bar.
        app.buttons["BackButton"].tap()
        let secondMap = app.staticTexts["Page 2"]
        XCTAssertTrue(secondMap.waitForExistence(timeout: 10), "No way back to the list\n\(app.debugDescription)")
        keepScreenshot("iPhone list of maps")
        secondMap.tap()

        XCTAssertTrue(waitForAMap(), "Choosing a map in the list didn't show it\n\(app.debugDescription)")
        XCTAssertFalse(secondMap.isHittable, "The list still covers the map")

        // Back in the list, the map that was showing can be chosen again.
        app.buttons["BackButton"].tap()
        XCTAssertTrue(secondMap.waitForExistence(timeout: 10), app.debugDescription)
        secondMap.tap()
        XCTAssertTrue(waitForAMap(), "Choosing the same map again didn't show it\n\(app.debugDescription)")
        XCTAssertFalse(secondMap.isHittable, "The list still covers the map")
    }

    /// Print is enabled once a map is loaded and cut into pages.
    private func waitForAMap() -> Bool {
        let print = app.buttons["Print"]
        let isReady = NSPredicate(format: "exists == true AND enabled == true")
        return XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: isReady, object: print)],
                                timeout: 30) == .completed
    }

    private func keepScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
