//
//  StreakPeriod.swift
//  Since
//

import Foundation
import SwiftData

@Model
final class StreakPeriod {
    var id: UUID
    var startDate: Date
    var endDate: Date?
    var note: String?
    var tracker: Tracker?

    init(
        id: UUID = UUID(),
        startDate: Date = .now,
        endDate: Date? = nil,
        note: String? = nil
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.note = note
    }
}
