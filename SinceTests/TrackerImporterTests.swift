//
//  TrackerImporterTests.swift
//  SinceTests
//

import Testing
import Foundation
import SwiftData
@testable import Since

@MainActor
struct TrackerImporterTests {
    private func makeContext() throws -> ModelContext {
        let schema = Schema([Tracker.self, StreakPeriod.self, Milestone.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    private func makeDTO(
        id: UUID = UUID(),
        name: String = "Smoking",
        streakPeriods: [StreakPeriodDTO] = [],
        milestones: [MilestoneDTO] = []
    ) -> TrackerExportDTO {
        TrackerExportDTO(
            id: id,
            name: name,
            icon: "flame.fill",
            colorHex: "#FF0000",
            category: nil,
            createdDate: .now,
            displayFormatOverride: nil,
            streakPeriods: streakPeriods,
            milestones: milestones
        )
    }

    // MARK: - parse

    @Test func parseThrowsOnInvalidJSON() {
        let data = Data("not json".utf8)
        #expect(throws: TrackerImportError.self) {
            try TrackerImporter.parse(data)
        }
    }

    @Test func parseThrowsOnUnsupportedSchemaVersion() throws {
        let file = TrackerBackupFile(schemaVersion: currentBackupSchemaVersion + 1, trackers: [])
        let data = try TrackerBackupCoding.encoder.encode(file)

        #expect(throws: TrackerImportError.self) {
            try TrackerImporter.parse(data)
        }
    }

    @Test func parseSucceedsForCurrentSchemaVersion() throws {
        let dto = makeDTO()
        let file = TrackerBackupFile(schemaVersion: currentBackupSchemaVersion, trackers: [dto])
        let data = try TrackerBackupCoding.encoder.encode(file)

        let parsed = try TrackerImporter.parse(data)
        #expect(parsed.trackers.count == 1)
    }

    // MARK: - plan

    @Test func planClassifiesTrackerWithNoMatchingIDAsNew() throws {
        let context = try makeContext()
        let existing = Tracker(name: "Drinking", icon: "drop.fill", colorHex: "#00FF00")
        context.insert(existing)

        let file = TrackerBackupFile(schemaVersion: currentBackupSchemaVersion, trackers: [makeDTO()])
        let plan = TrackerImporter.plan(for: file, existing: [existing])

        #expect(plan.items.count == 1)
        #expect(plan.items[0].isConflict == false)
    }

    @Test func planClassifiesTrackerWithMatchingIDAsConflict() throws {
        let context = try makeContext()
        let sharedID = UUID()
        let existing = Tracker(id: sharedID, name: "Smoking", icon: "flame.fill", colorHex: "#FF0000")
        context.insert(existing)

        let file = TrackerBackupFile(schemaVersion: currentBackupSchemaVersion, trackers: [makeDTO(id: sharedID)])
        let plan = TrackerImporter.plan(for: file, existing: [existing])

        #expect(plan.items[0].isConflict)
        #expect(plan.items[0].conflictingTracker === existing)
    }

    // MARK: - commit: new trackers

    @Test func commitInsertsNewTrackerWithChildren() throws {
        let context = try makeContext()
        let dto = makeDTO(
            streakPeriods: [StreakPeriodDTO(id: UUID(), startDate: .now.addingTimeInterval(-86400), endDate: nil, note: nil)],
            milestones: [MilestoneDTO(id: UUID(), label: "1 Week", triggerDuration: 7 * 86400)]
        )
        let file = TrackerBackupFile(schemaVersion: currentBackupSchemaVersion, trackers: [dto])
        let plan = TrackerImporter.plan(for: file, existing: [])

        let summary = TrackerImporter.commit(plan, resolutions: [:], into: context)
        try context.save()

        let descriptor = FetchDescriptor<Tracker>()
        let trackers = try context.fetch(descriptor)

        #expect(summary.imported == 1)
        #expect(trackers.count == 1)
        #expect(trackers[0].id == dto.id)
        #expect(trackers[0].streakPeriods.count == 1)
        #expect(trackers[0].milestones.count == 1)
        #expect(trackers[0].milestones[0].notificationIdentifier == nil)
    }

    // MARK: - commit: skip

    @Test func commitSkipLeavesExistingTrackerUnchanged() throws {
        let context = try makeContext()
        let sharedID = UUID()
        let existing = Tracker(id: sharedID, name: "Original Name", icon: "flame.fill", colorHex: "#FF0000")
        context.insert(existing)

        let dto = makeDTO(id: sharedID, name: "Imported Name")
        let file = TrackerBackupFile(schemaVersion: currentBackupSchemaVersion, trackers: [dto])
        let plan = TrackerImporter.plan(for: file, existing: [existing])

        let summary = TrackerImporter.commit(plan, resolutions: [sharedID: .skip], into: context)
        try context.save()

        #expect(summary.skipped == 1)
        #expect(existing.name == "Original Name")
    }

    @Test func commitDefaultsToSkipWhenNoResolutionProvided() throws {
        let context = try makeContext()
        let sharedID = UUID()
        let existing = Tracker(id: sharedID, name: "Original Name", icon: "flame.fill", colorHex: "#FF0000")
        context.insert(existing)

        let dto = makeDTO(id: sharedID, name: "Imported Name")
        let file = TrackerBackupFile(schemaVersion: currentBackupSchemaVersion, trackers: [dto])
        let plan = TrackerImporter.plan(for: file, existing: [existing])

        let summary = TrackerImporter.commit(plan, resolutions: [:], into: context)

        #expect(summary.skipped == 1)
        #expect(existing.name == "Original Name")
    }

    // MARK: - commit: merge

    @Test func commitMergeAddsMissingMilestonesAndKeepsExistingTrackerFields() throws {
        let context = try makeContext()
        let sharedID = UUID()
        let existing = Tracker(id: sharedID, name: "Original Name", icon: "flame.fill", colorHex: "#FF0000")
        context.insert(existing)
        existing.milestones.append(Milestone(label: "Existing Milestone", triggerDuration: 86400))

        let dto = makeDTO(
            id: sharedID,
            name: "Imported Name",
            milestones: [MilestoneDTO(id: UUID(), label: "New Milestone", triggerDuration: 30 * 86400)]
        )
        let file = TrackerBackupFile(schemaVersion: currentBackupSchemaVersion, trackers: [dto])
        let plan = TrackerImporter.plan(for: file, existing: [existing])

        let summary = TrackerImporter.commit(plan, resolutions: [sharedID: .merge], into: context)
        try context.save()

        #expect(summary.merged == 1)
        #expect(existing.name == "Original Name")
        #expect(existing.milestones.count == 2)
        #expect(Set(existing.milestones.map(\.label)) == ["Existing Milestone", "New Milestone"])
    }

    @Test func commitMergeSkipsMilestoneAlreadyPresentByID() throws {
        let context = try makeContext()
        let sharedID = UUID()
        let existing = Tracker(id: sharedID, name: "Tracker", icon: "flame.fill", colorHex: "#FF0000")
        context.insert(existing)
        let milestoneID = UUID()
        existing.milestones.append(Milestone(id: milestoneID, label: "Local Version", triggerDuration: 86400))

        let dto = makeDTO(
            id: sharedID,
            milestones: [MilestoneDTO(id: milestoneID, label: "Imported Version", triggerDuration: 999)]
        )
        let file = TrackerBackupFile(schemaVersion: currentBackupSchemaVersion, trackers: [dto])
        let plan = TrackerImporter.plan(for: file, existing: [existing])

        TrackerImporter.commit(plan, resolutions: [sharedID: .merge], into: context)

        #expect(existing.milestones.count == 1)
        #expect(existing.milestones[0].label == "Local Version")
    }

    @Test func commitMergeAddsClosedStreakPeriodsNotAlreadyPresent() throws {
        let context = try makeContext()
        let sharedID = UUID()
        let existing = Tracker(id: sharedID, name: "Tracker", icon: "flame.fill", colorHex: "#FF0000")
        context.insert(existing)
        existing.streakPeriods.append(StreakPeriod(startDate: .now.addingTimeInterval(-86400)))

        let closedPeriod = StreakPeriodDTO(
            id: UUID(),
            startDate: .now.addingTimeInterval(-86400 * 10),
            endDate: .now.addingTimeInterval(-86400 * 8),
            note: "Old streak"
        )
        let dto = makeDTO(id: sharedID, streakPeriods: [closedPeriod])
        let file = TrackerBackupFile(schemaVersion: currentBackupSchemaVersion, trackers: [dto])
        let plan = TrackerImporter.plan(for: file, existing: [existing])

        TrackerImporter.commit(plan, resolutions: [sharedID: .merge], into: context)

        #expect(existing.streakPeriods.count == 2)
        #expect(existing.streakPeriods.contains { $0.note == "Old streak" })
    }

    @Test func commitMergeDropsImportedOpenPeriodWhenLocalTrackerAlreadyHasAnActiveOne() throws {
        let context = try makeContext()
        let sharedID = UUID()
        let existing = Tracker(id: sharedID, name: "Tracker", icon: "flame.fill", colorHex: "#FF0000")
        context.insert(existing)
        existing.streakPeriods.append(StreakPeriod(startDate: .now.addingTimeInterval(-86400)))

        let importedOpenPeriod = StreakPeriodDTO(id: UUID(), startDate: .now.addingTimeInterval(-86400 * 20), endDate: nil, note: nil)
        let dto = makeDTO(id: sharedID, streakPeriods: [importedOpenPeriod])
        let file = TrackerBackupFile(schemaVersion: currentBackupSchemaVersion, trackers: [dto])
        let plan = TrackerImporter.plan(for: file, existing: [existing])

        TrackerImporter.commit(plan, resolutions: [sharedID: .merge], into: context)

        #expect(existing.streakPeriods.count == 1)
        #expect(existing.streakPeriods.filter { $0.endDate == nil }.count == 1)
    }

    @Test func commitMergeAddsImportedOpenPeriodWhenLocalTrackerHasNoActiveOne() throws {
        let context = try makeContext()
        let sharedID = UUID()
        let existing = Tracker(id: sharedID, name: "Tracker", icon: "flame.fill", colorHex: "#FF0000")
        context.insert(existing)
        // No active streak locally.

        let importedOpenPeriod = StreakPeriodDTO(id: UUID(), startDate: .now.addingTimeInterval(-86400 * 20), endDate: nil, note: nil)
        let dto = makeDTO(id: sharedID, streakPeriods: [importedOpenPeriod])
        let file = TrackerBackupFile(schemaVersion: currentBackupSchemaVersion, trackers: [dto])
        let plan = TrackerImporter.plan(for: file, existing: [existing])

        TrackerImporter.commit(plan, resolutions: [sharedID: .merge], into: context)

        #expect(existing.activeStreakPeriod != nil)
        #expect(existing.activeStreakPeriod?.id == importedOpenPeriod.id)
    }

    // MARK: - commit: overwrite

    @Test func commitOverwriteReplacesTrackerFieldsAndFullHistory() throws {
        let context = try makeContext()
        let sharedID = UUID()
        let existing = Tracker(id: sharedID, name: "Original Name", icon: "flame.fill", colorHex: "#FF0000")
        context.insert(existing)
        existing.streakPeriods.append(StreakPeriod(startDate: .now.addingTimeInterval(-86400)))
        existing.milestones.append(Milestone(label: "Stale Milestone", triggerDuration: 86400))

        let dto = makeDTO(
            id: sharedID,
            name: "Imported Name",
            streakPeriods: [StreakPeriodDTO(id: UUID(), startDate: .now.addingTimeInterval(-86400 * 5), endDate: nil, note: nil)],
            milestones: [MilestoneDTO(id: UUID(), label: "Fresh Milestone", triggerDuration: 30 * 86400)]
        )
        let file = TrackerBackupFile(schemaVersion: currentBackupSchemaVersion, trackers: [dto])
        let plan = TrackerImporter.plan(for: file, existing: [existing])

        let summary = TrackerImporter.commit(plan, resolutions: [sharedID: .overwrite], into: context)
        try context.save()

        #expect(summary.overwritten == 1)
        #expect(existing.name == "Imported Name")
        #expect(existing.streakPeriods.count == 1)
        #expect(existing.milestones.count == 1)
        #expect(existing.milestones[0].label == "Fresh Milestone")
    }
}
