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

struct TimeDisplayFormatTests {
    @Test func smartShowsMinutesUnderAnHour()  {
        #expect(TimeDisplayFormat.smart.string(from: 90) == "1 minute")
        #expect(TimeDisplayFormat.smart.string(from: 60 * 45) == "45 minutes")
    }

    @Test func smartShowsHoursUnderADay() {
        #expect(TimeDisplayFormat.smart.string(from: 3600) == "1 hour")
        #expect(TimeDisplayFormat.smart.string(from: 3600 * 5) == "5 hours")
    }

    @Test func smartShowsDaysAtOrAboveADay() {
        #expect(TimeDisplayFormat.smart.string(from: 86400) == "1 day")
        #expect(TimeDisplayFormat.smart.string(from: 86400 * 5) == "5 days")
    }

    @Test func daysOnlyAlwaysShowsDays() {
        #expect(TimeDisplayFormat.daysOnly.string(from: 3600) == "0 days")
        #expect(TimeDisplayFormat.daysOnly.string(from: 86400 * 2) == "2 days")
    }

    @Test func detailedShowsDaysHoursMinutes() {
        let interval: TimeInterval = 86400 * 3 + 3600 * 4 + 60 * 12
        #expect(TimeDisplayFormat.detailed.string(from: interval) == "3d 4h 12m")
    }

    @Test func smartSecondsUntilChangeTicksByMinuteUnderAnHour() {
        #expect(TimeDisplayFormat.smart.secondsUntilDisplayChange(elapsedSeconds: 90) == 30)
        #expect(TimeDisplayFormat.smart.secondsUntilDisplayChange(elapsedSeconds: 0) == 60)
    }

    @Test func smartSecondsUntilChangeTicksByHourUnderADay() {
        #expect(TimeDisplayFormat.smart.secondsUntilDisplayChange(elapsedSeconds: 3600 + 100) == 3500)
    }

    @Test func smartSecondsUntilChangeTicksByDayAtOrAboveADay() {
        #expect(TimeDisplayFormat.smart.secondsUntilDisplayChange(elapsedSeconds: 86400 + 100) == 86300)
    }

    @Test func daysOnlySecondsUntilChangeAlwaysTicksByDay() {
        #expect(TimeDisplayFormat.daysOnly.secondsUntilDisplayChange(elapsedSeconds: 100) == 86300)
    }

    @Test func detailedSecondsUntilChangeAlwaysTicksByMinute() {
        #expect(TimeDisplayFormat.detailed.secondsUntilDisplayChange(elapsedSeconds: 86400 + 3600 + 100) == 20)
    }
}

@MainActor
struct TrackerDisplayTests {
    private func makeContext() throws -> ModelContext {
        let schema = Schema([Tracker.self, StreakPeriod.self, Milestone.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    @Test func elapsedTimeStringUsesOverrideFormat() throws {
        let context = try makeContext()
        let tracker = Tracker(
            name: "Smoking",
            icon: "flame.fill",
            colorHex: "#FF0000",
            displayFormatOverride: .daysOnly
        )
        context.insert(tracker)
        tracker.streakPeriods.append(StreakPeriod(startDate: .now.addingTimeInterval(-86400 * 2)))

        #expect(tracker.elapsedTimeString(asOf: .now) == "2 days")
    }

    @Test func elapsedTimeStringIsNilWithoutAnActiveStreak() throws {
        let context = try makeContext()
        let tracker = Tracker(name: "Smoking", icon: "flame.fill", colorHex: "#FF0000")
        context.insert(tracker)

        #expect(tracker.elapsedTimeString() == nil)
    }

    @Test func nextDisplayChangeDateReflectsCurrentUnitUnderSmartFormat() throws {
        let context = try makeContext()
        let tracker = Tracker(name: "Smoking", icon: "flame.fill", colorHex: "#FF0000")
        context.insert(tracker)
        let now = Date.now
        tracker.streakPeriods.append(StreakPeriod(startDate: now.addingTimeInterval(-90)))

        let next = try #require(tracker.nextDisplayChangeDate(after: now, format: .smart))
        #expect(next.timeIntervalSince(now) == 30)
    }

    @Test func nextDisplayChangeDateIsNilWithoutAnActiveStreak() throws {
        let context = try makeContext()
        let tracker = Tracker(name: "Smoking", icon: "flame.fill", colorHex: "#FF0000")
        context.insert(tracker)

        #expect(tracker.nextDisplayChangeDate(format: .smart) == nil)
    }

    @Test func nextMilestonePicksSoonestUnreachedOne() throws {
        let context = try makeContext()
        let tracker = Tracker(name: "Smoking", icon: "flame.fill", colorHex: "#FF0000")
        context.insert(tracker)
        let start = Date.now.addingTimeInterval(-86400 * 5)
        tracker.streakPeriods.append(StreakPeriod(startDate: start))

        let reached = Milestone(label: "3 Days", triggerDuration: 86400 * 3)
        let soonestUnreached = Milestone(label: "1 Week", triggerDuration: 86400 * 7)
        let laterUnreached = Milestone(label: "1 Month", triggerDuration: 86400 * 30)
        tracker.milestones.append(contentsOf: [reached, soonestUnreached, laterUnreached])

        #expect(tracker.nextMilestone() === soonestUnreached)
    }

    @Test func nextMilestoneIsNilWhenAllReached() throws {
        let context = try makeContext()
        let tracker = Tracker(name: "Smoking", icon: "flame.fill", colorHex: "#FF0000")
        context.insert(tracker)
        tracker.streakPeriods.append(StreakPeriod(startDate: .now.addingTimeInterval(-86400 * 10)))
        tracker.milestones.append(Milestone(label: "3 Days", triggerDuration: 86400 * 3))

        #expect(tracker.nextMilestone() == nil)
    }

    @Test func remainingTimeStringCountsDownToMilestone() throws {
        let context = try makeContext()
        let tracker = Tracker(name: "Smoking", icon: "flame.fill", colorHex: "#FF0000", displayFormatOverride: .daysOnly)
        context.insert(tracker)
        let now = Date.now
        tracker.streakPeriods.append(StreakPeriod(startDate: now.addingTimeInterval(-86400 * 5)))

        let milestone = Milestone(label: "1 Week", triggerDuration: 86400 * 7)
        tracker.milestones.append(milestone)

        #expect(milestone.remainingTimeString(from: tracker, asOf: now) == "2 days")
    }

    @Test func effectiveDisplayFormatFallsBackToAppSettingsDefaultWhenNoOverride() throws {
        let originalDefault = AppSettings.defaultDisplayFormat
        defer { AppSettings.defaultDisplayFormat = originalDefault }

        let context = try makeContext()
        let tracker = Tracker(name: "Smoking", icon: "flame.fill", colorHex: "#FF0000")
        context.insert(tracker)

        AppSettings.defaultDisplayFormat = .detailed
        #expect(tracker.effectiveDisplayFormat == .detailed)

        AppSettings.defaultDisplayFormat = .daysOnly
        #expect(tracker.effectiveDisplayFormat == .daysOnly)
    }

    @Test func effectiveDisplayFormatPrefersOverrideOverAppSettingsDefault() throws {
        let originalDefault = AppSettings.defaultDisplayFormat
        defer { AppSettings.defaultDisplayFormat = originalDefault }

        let context = try makeContext()
        let tracker = Tracker(
            name: "Smoking",
            icon: "flame.fill",
            colorHex: "#FF0000",
            displayFormatOverride: .daysOnly
        )
        context.insert(tracker)

        AppSettings.defaultDisplayFormat = .detailed
        #expect(tracker.effectiveDisplayFormat == .daysOnly)
    }
}

// Serialized: every test here mutates the same process-wide App Group UserDefaults, so running
// them concurrently (Swift Testing's default within a suite) races on shared state.
@Suite(.serialized)
struct AppSettingsTests {
    @Test func defaultDisplayFormatRoundTrips() {
        let original = AppSettings.defaultDisplayFormat
        defer { AppSettings.defaultDisplayFormat = original }

        AppSettings.defaultDisplayFormat = .detailed
        #expect(AppSettings.defaultDisplayFormat == .detailed)

        AppSettings.defaultDisplayFormat = .daysOnly
        #expect(AppSettings.defaultDisplayFormat == .daysOnly)
    }

    @Test func lockScreenPrivacyEnabledDefaultsToTrue() {
        let defaults = UserDefaults(suiteName: SharedModelContainer.appGroupIdentifier) ?? .standard
        let original = defaults.object(forKey: AppSettings.lockScreenPrivacyEnabledKey)
        defaults.removeObject(forKey: AppSettings.lockScreenPrivacyEnabledKey)
        defer {
            if let original {
                defaults.set(original, forKey: AppSettings.lockScreenPrivacyEnabledKey)
            } else {
                defaults.removeObject(forKey: AppSettings.lockScreenPrivacyEnabledKey)
            }
        }

        #expect(AppSettings.lockScreenPrivacyEnabled == true)
    }

    @Test func lockScreenPrivacyEnabledRoundTrips() {
        let original = AppSettings.lockScreenPrivacyEnabled
        defer { AppSettings.lockScreenPrivacyEnabled = original }

        AppSettings.lockScreenPrivacyEnabled = false
        #expect(AppSettings.lockScreenPrivacyEnabled == false)

        AppSettings.lockScreenPrivacyEnabled = true
        #expect(AppSettings.lockScreenPrivacyEnabled == true)
    }
}

struct CompactDurationStringTests {
    @Test func showsDaysWhenAtLeastADay() {
        let interval: TimeInterval = 86400 * 12 + 3600 * 5
        #expect(interval.compactDurationString == "12d")
    }

    @Test func showsHoursUnderADay() {
        let interval: TimeInterval = 3600 * 5 + 60 * 30
        #expect(interval.compactDurationString == "5h")
    }

    @Test func showsMinutesUnderAnHour() {
        #expect(TimeInterval(90).compactDurationString == "1m")
        #expect(TimeInterval(0).compactDurationString == "0m")
    }
}

@MainActor
struct TrackerResetTests {
    private func makeContext() throws -> ModelContext {
        let schema = Schema([Tracker.self, StreakPeriod.self, Milestone.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    @Test func resetClosesActivePeriodAndOpensANewOne() throws {
        let context = try makeContext()
        let tracker = Tracker(name: "Smoking", icon: "flame.fill", colorHex: "#FF0000")
        context.insert(tracker)
        let start = Date.now.addingTimeInterval(-86400 * 4)
        tracker.streakPeriods.append(StreakPeriod(startDate: start))

        let resetDate = Date.now
        Tracker.resetStreak(on: tracker, note: "Slipped up", asOf: resetDate)

        #expect(tracker.streakPeriods.count == 2)
        let closed = try #require(tracker.streakPeriods.first { $0.startDate == start })
        #expect(closed.endDate == resetDate)
        #expect(closed.note == "Slipped up")

        let active = try #require(tracker.activeStreakPeriod)
        #expect(active.startDate == resetDate)
    }

    @Test func resetTrimsBlankNoteToNil() throws {
        let context = try makeContext()
        let tracker = Tracker(name: "Smoking", icon: "flame.fill", colorHex: "#FF0000")
        context.insert(tracker)
        tracker.streakPeriods.append(StreakPeriod(startDate: .now.addingTimeInterval(-86400)))

        Tracker.resetStreak(on: tracker, note: "   ")

        let closed = try #require(tracker.pastStreakPeriods.first)
        #expect(closed.note == nil)
    }

    @Test func pastStreakPeriodsExcludesActiveAndSortsNewestFirst() throws {
        let context = try makeContext()
        let tracker = Tracker(name: "Smoking", icon: "flame.fill", colorHex: "#FF0000")
        context.insert(tracker)

        let older = StreakPeriod(
            startDate: .now.addingTimeInterval(-86400 * 10),
            endDate: .now.addingTimeInterval(-86400 * 8)
        )
        let newer = StreakPeriod(
            startDate: .now.addingTimeInterval(-86400 * 5),
            endDate: .now.addingTimeInterval(-86400 * 3)
        )
        let active = StreakPeriod(startDate: .now.addingTimeInterval(-86400))
        tracker.streakPeriods.append(contentsOf: [older, newer, active])

        #expect(tracker.pastStreakPeriods == [newer, older])
    }
}
