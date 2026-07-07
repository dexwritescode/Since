//
//  SinceUITests.swift
//  SinceUITests
//
//  Created by Dexter Darwich on 2026-07-02.
//

import XCTest

final class SinceUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testAddingATrackerShowsItInTheList() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        app.buttons["Add Tracker"].tap()

        XCTAssertTrue(app.staticTexts["New Tracker"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testDeletingATrackerRemovesItFromTheList() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        app.buttons["Add Tracker"].tap()
        XCTAssertTrue(app.staticTexts["New Tracker"].waitForExistence(timeout: 2))

        app.staticTexts["New Tracker"].swipeLeft()
        app.buttons["Delete"].tap()

        XCTAssertFalse(app.staticTexts["New Tracker"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let app = XCUIApplication()
            app.launchArguments = ["--ui-testing"]
            app.launch()
        }
    }
}
