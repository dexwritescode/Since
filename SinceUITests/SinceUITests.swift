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
    func testTappingATrackerOpensDetailView() throws {
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

        XCTAssertTrue(app.buttons["Edit"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Reset Streak"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testEditingATrackerFromDetailViewPersistsChanges() throws {
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

        XCTAssertTrue(app.buttons["Edit"].waitForExistence(timeout: 2))
        app.buttons["Edit"].tap()

        let editNameField = app.textFields["Tracker name"]
        XCTAssertTrue(editNameField.waitForExistence(timeout: 2))
        XCTAssertEqual(editNameField.value as? String, "Original Name")

        editNameField.tap()
        if let existingValue = editNameField.value as? String {
            editNameField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: existingValue.count))
        }
        editNameField.typeText("Renamed Tracker")
        app.buttons["Save"].tap()

        XCTAssertTrue(app.navigationBars["Renamed Tracker"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testResettingAStreakAddsAHistoryEntry() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        app.buttons["Add Tracker"].tap()
        let nameField = app.textFields["Tracker name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.tap()
        nameField.typeText("Streak Tracker")
        app.buttons["Save"].tap()

        XCTAssertTrue(app.staticTexts["Streak Tracker"].waitForExistence(timeout: 2))
        app.staticTexts["Streak Tracker"].tap()

        XCTAssertTrue(app.staticTexts["No past streaks yet"].waitForExistence(timeout: 2))

        app.buttons["Reset Streak"].tap()

        let noteField = app.textFields["Reason for resetting"]
        XCTAssertTrue(noteField.waitForExistence(timeout: 2))
        noteField.tap()
        noteField.typeText("Slipped up")

        app.buttons["Reset"].tap()

        XCTAssertFalse(app.staticTexts["No past streaks yet"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Slipped up"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testOpeningSettingsShowsDisplayAndNotificationsSections() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        app.buttons["Settings"].tap()

        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Default Time Format"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Milestone Notifications"].waitForExistence(timeout: 2))

        app.buttons["Done"].tap()

        XCTAssertFalse(app.navigationBars["Settings"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testChangingDefaultTimeFormatAffectsTrackersWithoutOverride() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        app.buttons["Add Tracker"].tap()
        let nameField = app.textFields["Tracker name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.tap()
        nameField.typeText("Format Tracker")
        app.buttons["Save"].tap()

        XCTAssertTrue(app.staticTexts["Format Tracker"].waitForExistence(timeout: 2))

        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 2))

        app.buttons["Default Time Format"].tap()
        app.buttons["Detailed"].tap()

        app.buttons["Done"].tap()

        XCTAssertTrue(app.staticTexts["0d 0h 0m"].waitForExistence(timeout: 2))
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
    func testAddingMilestoneWithPresetFromTrackerDetailView() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        app.buttons["Add Tracker"].tap()
        let nameField = app.textFields["Tracker name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.tap()
        nameField.typeText("Preset Tracker")
        app.buttons["Save"].tap()

        XCTAssertTrue(app.staticTexts["Preset Tracker"].waitForExistence(timeout: 2))
        app.staticTexts["Preset Tracker"].tap()

        app.buttons["Add Milestone"].tap()

        let labelField = app.textFields["Label"]
        XCTAssertTrue(labelField.waitForExistence(timeout: 2))
        labelField.tap()
        if let existingValue = labelField.value as? String {
            labelField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: existingValue.count))
        }
        labelField.typeText("Big Month")

        app.buttons["1 Month"].tap()
        app.buttons["Save"].tap()

        XCTAssertTrue(app.staticTexts["Big Month"].waitForExistence(timeout: 2))
        // Truncates to whole days, and a little time has elapsed since the streak started.
        XCTAssertTrue(app.staticTexts["29 days left"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testDefaultMilestoneStateIsImmediatelySavableWithoutAnyInput() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        app.buttons["Add Tracker"].tap()
        let nameField = app.textFields["Tracker name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.tap()
        nameField.typeText("No Label Tracker")
        app.buttons["Save"].tap()

        XCTAssertTrue(app.staticTexts["No Label Tracker"].waitForExistence(timeout: 2))
        app.staticTexts["No Label Tracker"].tap()

        app.buttons["Add Milestone"].tap()
        XCTAssertTrue(app.textFields["Label"].waitForExistence(timeout: 2))

        // Touch nothing else — the default state (matching the pre-highlighted "1 Week" chip)
        // must already be valid, since a blank label is silently dropped/blocked on save.
        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.isEnabled)
        saveButton.tap()

        XCTAssertTrue(app.staticTexts["1 Week"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testTappingADifferentPresetWithoutCustomizingSyncsTheLabel() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        app.buttons["Add Tracker"].tap()
        let nameField = app.textFields["Tracker name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.tap()
        nameField.typeText("Synced Label Tracker")
        app.buttons["Save"].tap()

        XCTAssertTrue(app.staticTexts["Synced Label Tracker"].waitForExistence(timeout: 2))
        app.staticTexts["Synced Label Tracker"].tap()

        app.buttons["Add Milestone"].tap()
        XCTAssertTrue(app.textFields["Label"].waitForExistence(timeout: 2))

        // Default label is "1 Week" (matching the default 7-day value); switching to a
        // different preset without ever typing a custom label should re-sync the label too.
        app.buttons["1 Month"].tap()
        app.buttons["Save"].tap()

        XCTAssertTrue(app.staticTexts["1 Month"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["1 Week"].exists)
    }

    @MainActor
    func testAddingMilestoneWithPresetFromNewTrackerSheet() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        app.buttons["Add Tracker"].tap()
        let nameField = app.textFields["Tracker name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.tap()
        nameField.typeText("Inline Preset Tracker\n")

        for _ in 0..<3 where !app.buttons["Add Milestone"].exists {
            app.swipeUp()
        }
        XCTAssertTrue(app.buttons["Add Milestone"].waitForExistence(timeout: 2))
        app.buttons["Add Milestone"].tap()
        let labelField = app.textFields["Label"]
        XCTAssertTrue(labelField.waitForExistence(timeout: 2))
        labelField.tap()
        if let existingValue = labelField.value as? String {
            labelField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: existingValue.count))
        }
        labelField.typeText("One Week")

        app.buttons["1 Week"].tap()
        app.buttons["Save"].tap()

        XCTAssertTrue(app.staticTexts["Inline Preset Tracker"].waitForExistence(timeout: 2))
        app.staticTexts["Inline Preset Tracker"].tap()

        XCTAssertTrue(app.staticTexts["One Week"].waitForExistence(timeout: 2))
        // Truncates to whole days, and a little time has elapsed since the streak started.
        XCTAssertTrue(app.staticTexts["6 days left"].waitForExistence(timeout: 2))
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
