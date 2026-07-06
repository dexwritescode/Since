//
//  Tracker.swift
//  Since
//

import Foundation
import SwiftData

@Model
final class Tracker {
    var id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var category: String?
    var createdDate: Date
    var displayFormatOverride: TimeDisplayFormat?

    @Relationship(deleteRule: .cascade, inverse: \StreakPeriod.tracker)
    var streakPeriods: [StreakPeriod] = []

    @Relationship(deleteRule: .cascade, inverse: \Milestone.tracker)
    var milestones: [Milestone] = []

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        colorHex: String,
        category: String? = nil,
        createdDate: Date = .now,
        displayFormatOverride: TimeDisplayFormat? = nil
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.category = category
        self.createdDate = createdDate
        self.displayFormatOverride = displayFormatOverride
    }
}

extension Tracker {
    var activeStreakPeriod: StreakPeriod? {
        streakPeriods.first { $0.endDate == nil }
    }

    var currentStreakStartDate: Date? {
        activeStreakPeriod?.startDate
    }
}
