import XCTest

/// The About screen from the toolbar, with Paizo's Community Use Policy notice (tabletop-kit R6.1).
@MainActor
final class AboutUITests: XCTestCase {
    func testAboutShowsTheCommunityUseNotice() {
        let app = XCUIApplication()
        app.launch()
        let about = app.buttons["About"].firstMatch
        XCTAssertTrue(about.waitForExistence(timeout: 15), app.debugDescription)
        about.tap()
        let notice = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@",
                                                          "Mapsmith uses trademarks and/or copyrights owned by Paizo"))
        XCTAssertTrue(notice.firstMatch.waitForExistence(timeout: 5), "No Community Use Policy notice")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "About"
        attachment.lifetime = .keepAlways
        add(attachment)
        app.buttons["Done"].tap()
        XCTAssertTrue(app.staticTexts["Open a Map"].waitForExistence(timeout: 5))
    }
}
