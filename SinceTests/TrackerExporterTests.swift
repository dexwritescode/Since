//
//  TrackerExporterTests.swift
//  SinceTests
//

import Testing
import Foundation
import SwiftData
@testable import Since

@MainActor
struct TrackerExporterTests {
    private func makeContext() throws -> ModelContext {
        let schema = Schema([Tracker.self, StreakPeriod.self, Milestone.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    @Test func dtoIncludesTrackerStreakPeriodsAndMilestones() throws {
        let context = try makeContext()
        let tracker = Tracker(name: "Smoking", icon: "flame.fill", colorHex: "#FF0000", category: "Health")
        context.insert(tracker)
        tracker.streakPeriods.append(StreakPeriod(startDate: .now.addingTimeInterval(-86400 * 3), note: "note"))
        tracker.milestones.append(Milestone(label: "1 Week", triggerDuration: 7 * 86400, notificationIdentifier: "some-id"))

        let dto = TrackerExporter.dto(for: tracker)

        #expect(dto.id == tracker.id)
        #expect(dto.name == "Smoking")
        #expect(dto.category == "Health")
        #expect(dto.streakPeriods.count == 1)
        #expect(dto.streakPeriods[0].note == "note")
        #expect(dto.milestones.count == 1)
        #expect(dto.milestones[0].label == "1 Week")
    }

    @Test func milestoneDTODoesNotSerializeNotificationIdentifier() throws {
        let milestone = MilestoneDTO(id: UUID(), label: "1 Week", triggerDuration: 7 * 86400)
        let data = try TrackerBackupCoding.encoder.encode(milestone)
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(json["notificationIdentifier"] == nil)
    }

    @Test func documentForSingleTrackerWritesReadableJSONFile() throws {
        let context = try makeContext()
        let tracker = Tracker(name: "Drinking", icon: "drop.fill", colorHex: "#00FF00")
        context.insert(tracker)
        tracker.streakPeriods.append(StreakPeriod(startDate: .now.addingTimeInterval(-86400)))

        let document = try TrackerExporter.document(for: tracker)
        let data = try Data(contentsOf: document.fileURL)
        let file = try TrackerBackupCoding.decoder.decode(TrackerBackupFile.self, from: data)

        #expect(file.schemaVersion == currentBackupSchemaVersion)
        #expect(file.trackers.count == 1)
        #expect(file.trackers[0].name == "Drinking")
    }

    @Test func documentForAllTrackersIncludesEveryTracker() throws {
        let context = try makeContext()
        let first = Tracker(name: "Smoking", icon: "flame.fill", colorHex: "#FF0000")
        let second = Tracker(name: "Drinking", icon: "drop.fill", colorHex: "#00FF00")
        context.insert(first)
        context.insert(second)

        let document = try TrackerExporter.document(forAll: [first, second])
        let data = try Data(contentsOf: document.fileURL)
        let file = try TrackerBackupCoding.decoder.decode(TrackerBackupFile.self, from: data)

        #expect(file.trackers.count == 2)
        #expect(Set(file.trackers.map(\.name)) == ["Smoking", "Drinking"])
    }
}
