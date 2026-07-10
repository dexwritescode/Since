//
//  Tracker+Display.swift
//  Since
//

import Foundation

extension TimeDisplayFormat {
    /// Renders a non-negative duration per this format: `smart` shows the coarsest unit that's
    /// still meaningful (days once >= 1 day, else hours, else minutes); `daysOnly` always shows
    /// whole days; `detailed` shows a days/hours/minutes breakdown.
    func string(from interval: TimeInterval) -> String {
        let totalSeconds = max(0, Int(interval))
        let days = totalSeconds / 86400
        let hours = (totalSeconds % 86400) / 3600
        let minutes = (totalSeconds % 3600) / 60

        switch self {
        case .daysOnly:
            return "\(days) day\(days == 1 ? "" : "s")"
        case .detailed:
            return "\(days)d \(hours)h \(minutes)m"
        case .smart:
            if days >= 1 {
                return "\(days) day\(days == 1 ? "" : "s")"
            } else if hours >= 1 {
                return "\(hours) hour\(hours == 1 ? "" : "s")"
            } else {
                return "\(minutes) minute\(minutes == 1 ? "" : "s")"
            }
        }
    }
}

extension Tracker {
    /// `.smart` until Settings (SIN-6) adds a real global default to fall back to.
    var effectiveDisplayFormat: TimeDisplayFormat {
        displayFormatOverride ?? .smart
    }

    func elapsedTimeString(asOf date: Date = .now) -> String? {
        guard let start = currentStreakStartDate else { return nil }
        return effectiveDisplayFormat.string(from: date.timeIntervalSince(start))
    }

    /// The soonest milestone not yet reached, or nil if there isn't one (no active streak, or
    /// every milestone has already fired).
    func nextMilestone(asOf date: Date = .now) -> Milestone? {
        guard let start = currentStreakStartDate else { return nil }
        let elapsed = date.timeIntervalSince(start)
        return milestones
            .filter { $0.triggerDuration > elapsed }
            .min { $0.triggerDuration < $1.triggerDuration }
    }
}

extension Milestone {
    func remainingTimeString(from tracker: Tracker, asOf date: Date = .now) -> String? {
        guard let start = tracker.currentStreakStartDate else { return nil }
        let remaining = triggerDuration - date.timeIntervalSince(start)
        guard remaining > 0 else { return nil }
        return tracker.effectiveDisplayFormat.string(from: remaining)
    }
}
