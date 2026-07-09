//
//  SinceTests.swift
//  SinceTests
//
//  Created by Dexter Darwich on 2026-07-02.
//

import Testing
import SwiftUI
import SwiftData
@testable import Since

@MainActor
struct TrackerTests {
    private func makeContext() throws -> ModelContext {
        let schema = Schema([Tracker.self, StreakPeriod.self, Milestone.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    @Test func activeStreakPeriodIsTheOneWithNoEndDate() throws {
        let context = try makeContext()
        let tracker = Tracker(name: "Smoking", icon: "flame.fill", colorHex: "#FF0000")
        context.insert(tracker)

        let closed = StreakPeriod(
            startDate: .now.addingTimeInterval(-86400 * 10),
            endDate: .now.addingTimeInterval(-86400 * 5)
        )
        closed.tracker = tracker

        let active = StreakPeriod(startDate: .now.addingTimeInterval(-86400))
        active.tracker = tracker

        context.insert(closed)
        context.insert(active)

        #expect(tracker.activeStreakPeriod === active)
        #expect(tracker.currentStreakStartDate == active.startDate)
    }

    @Test func activeStreakPeriodIsNilWhenEveryPeriodIsClosed() throws {
        let context = try makeContext()
        let tracker = Tracker(name: "Drinking", icon: "drop.fill", colorHex: "#00FF00")
        context.insert(tracker)

        let closed = StreakPeriod(
            startDate: .now.addingTimeInterval(-86400 * 3),
            endDate: .now.addingTimeInterval(-86400)
        )
        closed.tracker = tracker
        context.insert(closed)

        #expect(tracker.activeStreakPeriod == nil)
        #expect(tracker.currentStreakStartDate == nil)
    }
}

@MainActor
struct MilestoneReconciliationTests {
    private func makeContext() throws -> ModelContext {
        let schema = Schema([Tracker.self, StreakPeriod.self, Milestone.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    @Test func addsNewMilestonesFromDrafts() throws {
        let context = try makeContext()
        let tracker = Tracker(name: "Smoking", icon: "flame.fill", colorHex: "#FF0000")
        context.insert(tracker)

        let draft = MilestoneDraft(id: UUID(), label: "One Week", days: 7)
        Tracker.reconcileMilestones(on: tracker, with: [draft], in: context)
        try context.save()

        let milestone = try #require(tracker.milestones.first)
        #expect(tracker.milestones.count == 1)
        #expect(milestone.label == "One Week")
        #expect(milestone.triggerDuration == 7 * 86400)
    }

    @Test func updatesExistingMilestoneMatchedByID() throws {
        let context = try makeContext()
        let tracker = Tracker(name: "Smoking", icon: "flame.fill", colorHex: "#FF0000")
        context.insert(tracker)

        let existingID = UUID()
        let milestone = Milestone(id: existingID, label: "Old Label", triggerDuration: 86400)
        tracker.milestones.append(milestone)

        let draft = MilestoneDraft(id: existingID, label: "New Label", days: 30)
        Tracker.reconcileMilestones(on: tracker, with: [draft], in: context)
        try context.save()

        let updated = try #require(tracker.milestones.first)
        #expect(tracker.milestones.count == 1)
        #expect(updated.label == "New Label")
        #expect(updated.triggerDuration == 30 * 86400)
    }

    @Test func deletesMilestonesNotPresentInDrafts() throws {
        let context = try makeContext()
        let tracker = Tracker(name: "Smoking", icon: "flame.fill", colorHex: "#FF0000")
        context.insert(tracker)
        tracker.milestones.append(Milestone(label: "Stale", triggerDuration: 86400))

        Tracker.reconcileMilestones(on: tracker, with: [], in: context)
        try context.save()

        #expect(tracker.milestones.isEmpty)
    }

    @Test func dropsDraftsWithBlankLabels() throws {
        let context = try makeContext()
        let tracker = Tracker(name: "Smoking", icon: "flame.fill", colorHex: "#FF0000")
        context.insert(tracker)

        let draft = MilestoneDraft(id: UUID(), label: "   ", days: 7)
        Tracker.reconcileMilestones(on: tracker, with: [draft], in: context)
        try context.save()

        #expect(tracker.milestones.isEmpty)
    }
}

struct ColorHexTests {
    @Test func sixDigitHexRoundTrips() {
        let color = Color(hex: "#4F8EF7")
        #expect(color.hexString == "#4F8EF7")
    }

    @Test func eightDigitHexIgnoresAlphaInRoundTrip() {
        let color = Color(hex: "#4F8EF7FF")
        #expect(color.hexString == "#4F8EF7")
    }
}
