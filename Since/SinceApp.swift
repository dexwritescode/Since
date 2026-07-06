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
        // Xcode sets this on any process hosting a test bundle, unit or UI —
        // covers SinceTests' host-app launch as well as SinceUITests.
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
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
