//
//  SinceApp.swift
//  Since
//
//  Created by Dexter Darwich on 2026-07-02.
//

import SwiftUI
import SwiftData

@main
struct SinceApp: App {
    private static let modelContainer: ModelContainer = {
        // XCTestConfigurationFilePath is set on a process that is itself hosting a
        // test bundle — true for SinceTests, since Since.app is its TEST_HOST. It is
        // NOT propagated to the separate Since.app process XCUITest launches as the
        // app-under-test, so SinceUITests instead passes --ui-testing explicitly via
        // XCUIApplication.launchArguments. Both are needed.
        let isUnitTestHost = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        let isUITestLaunch = CommandLine.arguments.contains("--ui-testing")
        if isUnitTestHost || isUITestLaunch {
            return SharedModelContainer.makeInMemory()
        }
        return SharedModelContainer.shared
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(Self.modelContainer)
    }
}
