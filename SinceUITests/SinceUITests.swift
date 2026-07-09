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

        let nameField = app.textFields["Tracker name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.tap()
        nameField.typeText("Smoke Free")

        app.buttons["Save"].tap()

        XCTAssertTrue(app.staticTexts["Smoke Free"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testCancelingNewTrackerSheetDiscardsIt() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        app.buttons["Add Tracker"].tap()

        let nameField = app.textFields["Tracker name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.tap()
        nameField.typeText("Discarded Tracker")

        app.buttons["Cancel"].tap()

        XCTAssertFalse(app.staticTexts["Discarded Tracker"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testTappingATrackerOpensEditSheetAndPersistsChanges() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        app.buttons["Add Tracker"].tap()
        let nameField = app.textFields["Tracker name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.tap()
        nameField.typeText("Original Name")
        app.buttons["Save"].tap()

        XCTAssertTrue(app.staticTexts["Original Name"].waitForExistence(timeout: 2))
        app.staticTexts["Original Name"].tap()

        let editNameField = app.textFields["Tracker name"]
        XCTAssertTrue(editNameField.waitForExistence(timeout: 2))
        XCTAssertEqual(editNameField.value as? String, "Original Name")

        editNameField.tap()
        if let existingValue = editNameField.value as? String {
            editNameField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: existingValue.count))
        }
        editNameField.typeText("Renamed Tracker")
        app.buttons["Save"].tap()

        XCTAssertTrue(app.staticTexts["Renamed Tracker"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["Original Name"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testDeletingATrackerRemovesItFromTheList() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        app.buttons["Add Tracker"].tap()
        let nameField = app.textFields["Tracker name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.tap()
        nameField.typeText("Temporary Tracker")
        app.buttons["Save"].tap()

        XCTAssertTrue(app.staticTexts["Temporary Tracker"].waitForExistence(timeout: 2))

        app.staticTexts["Temporary Tracker"].swipeLeft()
        app.buttons["Delete"].tap()

        XCTAssertFalse(app.staticTexts["Temporary Tracker"].waitForExistence(timeout: 2))
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
