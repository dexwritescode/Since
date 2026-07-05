//
//  SharedModelContainer.swift
//  Since
//

import Foundation
import SwiftData

enum SharedModelContainer {
    static let appGroupIdentifier = "group.com.dexwritescode.since"

    static let schema = Schema([Tracker.self, StreakPeriod.self, Milestone.self])

    static let shared: ModelContainer = {
        guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            fatalError("Could not resolve App Group container for \(appGroupIdentifier)")
        }

        let storeURL = appGroupURL.appendingPathComponent("Since.sqlite")
        let configuration = ModelConfiguration(schema: schema, url: storeURL)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create shared ModelContainer: \(error)")
        }
    }()

    // Used when launched with `--ui-testing` so UI tests don't read/write the real App Group store.
    static func makeInMemory() -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create in-memory ModelContainer: \(error)")
        }
    }
}
