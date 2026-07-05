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
