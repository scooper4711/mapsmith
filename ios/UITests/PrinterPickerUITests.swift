import XCTest

/// Choose Printer… opens the system printer picker, from the settings and from the Ink Prices sheet, on the iPad
/// and the iPhone alike.
@MainActor
final class PrinterPickerUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-UITestSample"]
        app.launch()
        let print = app.buttons["Print"]
        let isReady = NSPredicate(format: "exists == true AND enabled == true")
        XCTAssertEqual(XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: isReady, object: print)],
                                        timeout: 30), .completed, "No map was loaded\n\(app.debugDescription)")
    }

    func testChoosingAPrinterInTheSettingsOpensThePicker() {
        // The iPad can have the settings open already; the iPhone opens them on request.
        if hittableChoosePrinterButton() == nil { app.buttons["Settings"].tap() }
        tapChoosePrinterAndExpectThePicker()
    }

    func testChoosingAPrinterInInkPricesOpensThePicker() {
        app.buttons["Ink Prices"].tap()
        tapChoosePrinterAndExpectThePicker()
    }

    private func tapChoosePrinterAndExpectThePicker() {
        XCTAssertTrue(app.buttons["Choose Printer…"].firstMatch.waitForExistence(timeout: 10), app.debugDescription)
        let choose = hittableChoosePrinterButton()
        XCTAssertNotNil(choose, "No Choose Printer… button in reach\n\(app.debugDescription)")
        choose?.tap()

        let picker = app.navigationBars["Printer"]
        XCTAssertTrue(picker.waitForExistence(timeout: 10),
                      "Choose Printer… showed no printer picker\n\(app.debugDescription)")
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "Printer picker"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// The iPad's settings can stay open behind the Ink Prices sheet, so there may be two; the one in reach counts.
    private func hittableChoosePrinterButton() -> XCUIElement? {
        app.buttons.matching(identifier: "Choose Printer…").allElementsBoundByIndex.first { $0.isHittable }
    }
}
