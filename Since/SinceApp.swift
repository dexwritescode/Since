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
        if CommandLine.arguments.contains("--ui-testing") {
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
