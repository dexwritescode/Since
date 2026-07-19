//
//  TrackerBackupRoundTripTests.swift
//  SinceTests
//

import Testing
import Foundation
import SwiftData
@testable import Since

/// Exercises `TrackerExporter` and `TrackerImporter` chained together end to end — export writes
/// a real file, import reads that exact file back into a separate `ModelContext` — rather than
/// each in isolation against hand-built fixtures.
@MainActor
struct TrackerBackupRoundTripTests {
    private func makeContext() throws -> ModelContext {
        let schema = Schema([Tracker.self, StreakPeriod.self, Milestone.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    @Test func exportingAndImportingIntoAFreshStoreReproducesTheTracker() throws {
        let sourceContext = try makeContext()
        let original = Tracker(
            name: "Smoking",
            icon: "flame.fill",
            colorHex: "#FF6B35",
            category: "Health",
            displayFormatOverride: .daysOnly
        )
        sourceContext.insert(original)
        original.streakPeriods.append(
            StreakPeriod(startDate: .now.addingTimeInterval(-86400 * 10), endDate: .now.addingTimeInterval(-86400 * 8), note: "Relapsed")
        )
        original.streakPeriods.append(StreakPeriod(startDate: .now.addingTimeInterval(-86400 * 5)))
        original.milestones.append(Milestone(label: "1 Week", triggerDuration: 7 * 86400, notificationIdentifier: "pending-request-id"))
        try sourceContext.save()

        let document = try TrackerExporter.document(for: original)
        let fileData = try Data(contentsOf: document.fileURL)

        let destinationContext = try makeContext()
        let parsedFile = try TrackerImporter.parse(fileData)
        let plan = TrackerImporter.plan(for: parsedFile, existing: [])
        let summary = TrackerImporter.commit(plan, resolutions: [:], into: destinationContext)
        try destinationContext.save()

        #expect(summary.imported == 1)

        let imported = try #require(try destinationContext.fetch(FetchDescriptor<Tracker>()).first)
        #expect(imported.id == original.id)
        #expect(imported.name == "Smoking")
        #expect(imported.colorHex == "#FF6B35")
        #expect(imported.category == "Health")
        #expect(imported.displayFormatOverride == .daysOnly)
        #expect(imported.streakPeriods.count == 2)
        #expect(imported.milestones.count == 1)
        #expect(imported.milestones[0].label == "1 Week")
        // Notification identifiers never cross the export/import boundary — they're regenerated
        // locally, not carried over from the source device's pending requests.
        #expect(imported.milestones[0].notificationIdentifier == nil)
        #expect(imported.pastStreakPeriods.contains { $0.note == "Relapsed" })
    }

    @Test func exportingAllTrackersThenReimportingOnTopOfThemselvesIsAllConflicts() throws {
        let sourceContext = try makeContext()
        let first = Tracker(name: "Smoking", icon: "flame.fill", colorHex: "#FF0000")
        let second = Tracker(name: "Drinking", icon: "drop.fill", colorHex: "#00FF00")
        sourceContext.insert(first)
        sourceContext.insert(second)
        try sourceContext.save()

        let document = try TrackerExporter.document(forAll: [first, second])
        let fileData = try Data(contentsOf: document.fileURL)
        let parsedFile = try TrackerImporter.parse(fileData)

        // Re-importing the same export back into the store it came from — every tracker in the
        // file now matches an existing tracker by id, so nothing should be classified as new.
        let plan = TrackerImporter.plan(for: parsedFile, existing: [first, second])

        #expect(plan.items.count == 2)
        #expect(plan.items.allSatisfy { $0.isConflict })

        let summary = TrackerImporter.commit(plan, resolutions: [:], into: sourceContext)
        #expect(summary.skipped == 2)
        #expect(summary.imported == 0)
    }

    @Test func mergingAReimportAfterANewMilestoneWasAddedLocallyKeepsBothMilestones() throws {
        let sourceContext = try makeContext()
        let tracker = Tracker(name: "Smoking", icon: "flame.fill", colorHex: "#FF0000")
        sourceContext.insert(tracker)
        tracker.milestones.append(Milestone(label: "1 Week", triggerDuration: 7 * 86400))
        try sourceContext.save()

        // Export while the tracker only has the "1 Week" milestone — simulating an older backup.
        let document = try TrackerExporter.document(for: tracker)
        let fileData = try Data(contentsOf: document.fileURL)

        // A milestone gets added locally after the export was taken.
        tracker.milestones.append(Milestone(label: "1 Month", triggerDuration: 30 * 86400))
        try sourceContext.save()

        let parsedFile = try TrackerImporter.parse(fileData)
        let plan = TrackerImporter.plan(for: parsedFile, existing: [tracker])
        TrackerImporter.commit(plan, resolutions: [tracker.id: .merge], into: sourceContext)

        #expect(tracker.milestones.count == 2)
        #expect(Set(tracker.milestones.map(\.label)) == ["1 Week", "1 Month"])
    }
}
