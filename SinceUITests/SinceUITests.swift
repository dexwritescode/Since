//
//  SinceUITests.swift
//  SinceUITests
//
//  Created by Dexter Darwich on 2026-07-02.
//

import XCTest

/// Element-wait ceiling for all UI tests. CI runners are far slower than local machines;
/// `waitForExistence` returns as soon as the element appears, so passing runs don't pay this.
let uiTimeout: TimeInterval = 5

extension XCUIElement {
    /// Waits for the element to exist before tapping, failing the test if it never appears.
    func waitThenTap(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(waitForExistence(timeout: uiTimeout),
                      "Timed out waiting to tap \(self)", file: file, line: line)
        tap()
    }
}

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

        app.buttons["Add Tracker"].waitThenTap()

        let nameField = app.textFields["Tracker name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: uiTimeout))
        nameField.tap()
        nameField.typeText("Smoke Free")

        app.buttons["Save"].waitThenTap()

        XCTAssertTrue(app.staticTexts["Smoke Free"].waitForExistence(timeout: uiTimeout))
    }

    @MainActor
    func testCancelingNewTrackerSheetDiscardsIt() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        app.buttons["Add Tracker"].waitThenTap()

        let nameField = app.textFields["Tracker name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: uiTimeout))
        nameField.tap()
        nameField.typeText("Discarded Tracker")

        app.buttons["Cancel"].waitThenTap()

        XCTAssertFalse(app.staticTexts["Discarded Tracker"].waitForExistence(timeout: uiTimeout))
    }

    @MainActor
    func testTappingATrackerOpensDetailView() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        app.buttons["Add Tracker"].waitThenTap()
        let nameField = app.textFields["Tracker name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: uiTimeout))
        nameField.tap()
        nameField.typeText("Original Name")
        app.buttons["Save"].waitThenTap()

        XCTAssertTrue(app.staticTexts["Original Name"].waitForExistence(timeout: uiTimeout))
        app.staticTexts["Original Name"].tap()

        XCTAssertTrue(app.buttons["Edit"].waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(app.buttons["Reset Streak"].waitForExistence(timeout: uiTimeout))
    }

    @MainActor
    func testEditingATrackerFromDetailViewPersistsChanges() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        app.buttons["Add Tracker"].waitThenTap()
        let nameField = app.textFields["Tracker name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: uiTimeout))
        nameField.tap()
        nameField.typeText("Original Name")
        app.buttons["Save"].waitThenTap()

        XCTAssertTrue(app.staticTexts["Original Name"].waitForExistence(timeout: uiTimeout))
        app.staticTexts["Original Name"].tap()

        XCTAssertTrue(app.buttons["Edit"].waitForExistence(timeout: uiTimeout))
        app.buttons["Edit"].waitThenTap()

        let editNameField = app.textFields["Tracker name"]
        XCTAssertTrue(editNameField.waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(editNameField.value as? String, "Original Name")

        editNameField.tap()
        if let existingValue = editNameField.value as? String {
            editNameField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: existingValue.count))
        }
        editNameField.typeText("Renamed Tracker")
        app.buttons["Save"].waitThenTap()

        XCTAssertTrue(app.navigationBars["Renamed Tracker"].waitForExistence(timeout: uiTimeout))
    }

    @MainActor
    func testResettingAStreakAddsAHistoryEntry() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        app.buttons["Add Tracker"].waitThenTap()
        let nameField = app.textFields["Tracker name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: uiTimeout))
        nameField.tap()
        nameField.typeText("Streak Tracker")
        app.buttons["Save"].waitThenTap()

        XCTAssertTrue(app.staticTexts["Streak Tracker"].waitForExistence(timeout: uiTimeout))
        app.staticTexts["Streak Tracker"].tap()

        XCTAssertTrue(app.staticTexts["No past streaks yet"].waitForExistence(timeout: uiTimeout))

        app.buttons["Reset Streak"].waitThenTap()

        let noteField = app.textFields["Reason for resetting"]
        XCTAssertTrue(noteField.waitForExistence(timeout: uiTimeout))
        noteField.tap()
        noteField.typeText("Slipped up")

        app.buttons["Reset"].waitThenTap()

        XCTAssertFalse(app.staticTexts["No past streaks yet"].waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(app.staticTexts["Slipped up"].waitForExistence(timeout: uiTimeout))
    }

    @MainActor
    func testOpeningSettingsShowsDisplayAndNotificationsSections() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        app.buttons["Settings"].waitThenTap()

        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(app.staticTexts["Default Time Format"].waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(app.staticTexts["Milestone Notifications"].waitForExistence(timeout: uiTimeout))

        app.buttons["Done"].waitThenTap()

        XCTAssertFalse(app.navigationBars["Settings"].waitForExistence(timeout: uiTimeout))
    }

    @MainActor
    func testChangingDefaultTimeFormatAffectsTrackersWithoutOverride() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        app.buttons["Add Tracker"].waitThenTap()
        let nameField = app.textFields["Tracker name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: uiTimeout))
        nameField.tap()
        nameField.typeText("Format Tracker")
        app.buttons["Save"].waitThenTap()

        XCTAssertTrue(app.staticTexts["Format Tracker"].waitForExistence(timeout: uiTimeout))

        app.buttons["Settings"].waitThenTap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: uiTimeout))

        app.buttons["Default Time Format"].waitThenTap()
        app.buttons["Detailed"].waitThenTap()

        app.buttons["Done"].waitThenTap()

        XCTAssertTrue(app.staticTexts["0d 0h 0m"].waitForExistence(timeout: uiTimeout))
    }

    @MainActor
    func testDeletingATrackerRemovesItFromTheList() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        app.buttons["Add Tracker"].waitThenTap()
        let nameField = app.textFields["Tracker name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: uiTimeout))
        nameField.tap()
        nameField.typeText("Temporary Tracker")
        app.buttons["Save"].waitThenTap()

        XCTAssertTrue(app.staticTexts["Temporary Tracker"].waitForExistence(timeout: uiTimeout))

        app.staticTexts["Temporary Tracker"].swipeLeft()
        app.buttons["Delete"].waitThenTap()

        XCTAssertFalse(app.staticTexts["Temporary Tracker"].waitForExistence(timeout: uiTimeout))
    }

    @MainActor
    func testAddingMilestoneWithPresetFromTrackerDetailView() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        app.buttons["Add Tracker"].waitThenTap()
        let nameField = app.textFields["Tracker name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: uiTimeout))
        nameField.tap()
        nameField.typeText("Preset Tracker")
        app.buttons["Save"].waitThenTap()

        XCTAssertTrue(app.staticTexts["Preset Tracker"].waitForExistence(timeout: uiTimeout))
        app.staticTexts["Preset Tracker"].tap()

        app.buttons["Add Milestone"].waitThenTap()

        let labelField = app.textFields["Label"]
        XCTAssertTrue(labelField.waitForExistence(timeout: uiTimeout))
        labelField.tap()
        if let existingValue = labelField.value as? String {
            labelField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: existingValue.count))
        }
        labelField.typeText("Big Month")

        app.buttons["1 Month"].waitThenTap()
        app.buttons["Save"].waitThenTap()

        XCTAssertTrue(app.staticTexts["Big Month"].waitForExistence(timeout: uiTimeout))
        // Truncates to whole days, and a little time has elapsed since the streak started.
        XCTAssertTrue(app.staticTexts["29 days left"].waitForExistence(timeout: uiTimeout))
    }

    @MainActor
    func testDefaultMilestoneStateIsImmediatelySavableWithoutAnyInput() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        app.buttons["Add Tracker"].waitThenTap()
        let nameField = app.textFields["Tracker name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: uiTimeout))
        nameField.tap()
        nameField.typeText("No Label Tracker")
        app.buttons["Save"].waitThenTap()

        XCTAssertTrue(app.staticTexts["No Label Tracker"].waitForExistence(timeout: uiTimeout))
        app.staticTexts["No Label Tracker"].tap()

        app.buttons["Add Milestone"].waitThenTap()
        XCTAssertTrue(app.textFields["Label"].waitForExistence(timeout: uiTimeout))

        // Touch nothing else — the default state (matching the pre-highlighted "1 Week" chip)
        // must already be valid, since a blank label is silently dropped/blocked on save.
        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.isEnabled)
        saveButton.tap()

        XCTAssertTrue(app.staticTexts["1 Week"].waitForExistence(timeout: uiTimeout))
    }

    @MainActor
    func testTappingADifferentPresetWithoutCustomizingSyncsTheLabel() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        app.buttons["Add Tracker"].waitThenTap()
        let nameField = app.textFields["Tracker name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: uiTimeout))
        nameField.tap()
        nameField.typeText("Synced Label Tracker")
        app.buttons["Save"].waitThenTap()

        XCTAssertTrue(app.staticTexts["Synced Label Tracker"].waitForExistence(timeout: uiTimeout))
        app.staticTexts["Synced Label Tracker"].tap()

        app.buttons["Add Milestone"].waitThenTap()
        XCTAssertTrue(app.textFields["Label"].waitForExistence(timeout: uiTimeout))

        // Default label is "1 Week" (matching the default 7-day value); switching to a
        // different preset without ever typing a custom label should re-sync the label too.
        app.buttons["1 Month"].waitThenTap()
        app.buttons["Save"].waitThenTap()

        XCTAssertTrue(app.staticTexts["1 Month"].waitForExistence(timeout: uiTimeout))
        XCTAssertFalse(app.staticTexts["1 Week"].exists)
    }

    @MainActor
    func testAddingMilestoneWithPresetFromNewTrackerSheet() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        app.buttons["Add Tracker"].waitThenTap()
        let nameField = app.textFields["Tracker name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: uiTimeout))
        nameField.tap()
        nameField.typeText("Inline Preset Tracker\n")

        for _ in 0..<3 where !app.buttons["Add Milestone"].exists {
            app.swipeUp()
        }
        app.buttons["Add Milestone"].waitThenTap()
        let labelField = app.textFields["Label"]
        XCTAssertTrue(labelField.waitForExistence(timeout: uiTimeout))
        labelField.tap()
        if let existingValue = labelField.value as? String {
            labelField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: existingValue.count))
        }
        labelField.typeText("One Week")

        app.buttons["1 Week"].waitThenTap()
        app.buttons["Save"].waitThenTap()

        XCTAssertTrue(app.staticTexts["Inline Preset Tracker"].waitForExistence(timeout: uiTimeout))
        app.staticTexts["Inline Preset Tracker"].tap()

        XCTAssertTrue(app.staticTexts["One Week"].waitForExistence(timeout: uiTimeout))
        // Truncates to whole days, and a little time has elapsed since the streak started.
        XCTAssertTrue(app.staticTexts["6 days left"].waitForExistence(timeout: uiTimeout))
    }

    @MainActor
    func testSettingsShowsBackupSectionWithExportAndImportEntryPoints() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        app.buttons["Settings"].waitThenTap()

        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: uiTimeout))
        // Export/Import hand off to system UI (share sheet, Files picker) that XCUITest can't
        // reliably drive in CI — this only checks the entry points render, not the system flows.
        XCTAssertTrue(app.buttons["Export All Trackers"].waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(app.buttons["Import"].waitForExistence(timeout: uiTimeout))
    }

    @MainActor
    func testSearchingAndSelectingAnIconUpdatesTrackerIcon() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        app.buttons["Add Tracker"].waitThenTap()
        let nameField = app.textFields["Tracker name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: uiTimeout))
        nameField.tap()
        nameField.typeText("Icon Tracker")

        app.buttons["Icon"].waitThenTap()

        let searchField = app.searchFields["Search icons"]
        XCTAssertTrue(searchField.waitForExistence(timeout: uiTimeout))
        searchField.tap()
        searchField.typeText("figure.run")

        app.buttons["figure.run"].waitThenTap()

        // Selecting an icon pops back to the edit sheet automatically.
        XCTAssertTrue(nameField.waitForExistence(timeout: uiTimeout))

        app.buttons["Save"].waitThenTap()
        XCTAssertTrue(app.staticTexts["Icon Tracker"].waitForExistence(timeout: uiTimeout))
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
