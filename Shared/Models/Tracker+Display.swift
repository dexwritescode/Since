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

    /// Seconds from `elapsedSeconds` until this format's rendered string would next change —
    /// used to schedule the widget's next timeline reload instead of polling on a fixed interval.
    func secondsUntilDisplayChange(elapsedSeconds: Int) -> Int {
        switch self {
        case .daysOnly:
            return 86400 - elapsedSeconds % 86400
        case .detailed:
            return 60 - elapsedSeconds % 60
        case .smart:
            if elapsedSeconds >= 86400 {
                return 86400 - elapsedSeconds % 86400
            } else if elapsedSeconds >= 3600 {
                return 3600 - elapsedSeconds % 3600
            } else {
                return 60 - elapsedSeconds % 60
            }
        }
    }
}

extension TimeInterval {
    /// Ultra-compact rendering ("12d", "5h", "30m") for space-constrained contexts like Lock
    /// Screen circular/inline accessory widgets — independent of the user's chosen
    /// `TimeDisplayFormat`, since `detailed`'s "3d 4h 12m" simply can't fit there.
    var compactDurationString: String {
        let totalSeconds = max(0, Int(self))
        let days = totalSeconds / 86400
        let hours = (totalSeconds % 86400) / 3600
        let minutes = (totalSeconds % 3600) / 60

        if days >= 1 { return "\(days)d" }
        if hours >= 1 { return "\(hours)h" }
        return "\(minutes)m"
    }
}

extension Tracker {
    var effectiveDisplayFormat: TimeDisplayFormat {
        displayFormatOverride ?? AppSettings.defaultDisplayFormat
    }

    func elapsedTimeInterval(asOf date: Date = .now) -> TimeInterval? {
        guard let start = currentStreakStartDate else { return nil }
        return date.timeIntervalSince(start)
    }

    /// `format` lets a SwiftUI view pass in a value it observes (e.g. via `@AppStorage`) so the
    /// view re-renders when the global default changes. Falls back to `effectiveDisplayFormat`
    /// (which reads `AppSettings` directly, not observed by SwiftUI) for non-view callers.
    func elapsedTimeString(asOf date: Date = .now, format: TimeDisplayFormat? = nil) -> String? {
        guard let elapsed = elapsedTimeInterval(asOf: date) else { return nil }
        return (format ?? effectiveDisplayFormat).string(from: elapsed)
    }

    /// See `TimeInterval.compactDurationString` for why this ignores `effectiveDisplayFormat`.
    func compactElapsedText(asOf date: Date = .now) -> String? {
        elapsedTimeInterval(asOf: date)?.compactDurationString
    }

    /// The next moment this tracker's rendered elapsed-time string would change under `format`,
    /// or nil if there's no active streak. Used by the widget to schedule its next reload at a
    /// meaningful boundary instead of polling.
    func nextDisplayChangeDate(after date: Date = .now, format: TimeDisplayFormat) -> Date? {
        guard let elapsed = elapsedTimeInterval(asOf: date) else { return nil }
        let elapsedSeconds = max(0, Int(elapsed))
        let secondsUntilChange = format.secondsUntilDisplayChange(elapsedSeconds: elapsedSeconds)
        return date.addingTimeInterval(TimeInterval(secondsUntilChange))
    }

    /// The soonest milestone not yet reached, or nil if there isn't one (no active streak, or
    /// every milestone has already fired).
    func nextMilestone(asOf date: Date = .now) -> Milestone? {
        guard let elapsed = elapsedTimeInterval(asOf: date) else { return nil }
        return milestones
            .filter { $0.triggerDuration > elapsed }
            .min { $0.triggerDuration < $1.triggerDuration }
    }

    /// Closed streak periods, most recently started first.
    var pastStreakPeriods: [StreakPeriod] {
        streakPeriods
            .filter { $0.endDate != nil }
            .sorted { $0.startDate > $1.startDate }
    }

    /// Closes the active streak period (with an optional note) and opens a new one starting now.
    /// Does not save the context or reload widget timelines — callers own that.
    static func resetStreak(on tracker: Tracker, note: String?, asOf date: Date = .now) {
        let trimmedNote = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let active = tracker.activeStreakPeriod {
            active.endDate = date
            active.note = (trimmedNote?.isEmpty ?? true) ? nil : trimmedNote
        }
        tracker.streakPeriods.append(StreakPeriod(startDate: date))
    }
}

extension Milestone {
    /// See `Tracker.elapsedTimeString(asOf:format:)` for why `format` is a separate parameter.
    func remainingTimeString(from tracker: Tracker, asOf date: Date = .now, format: TimeDisplayFormat? = nil) -> String? {
        guard let elapsed = tracker.elapsedTimeInterval(asOf: date) else { return nil }
        let remaining = triggerDuration - elapsed
        guard remaining > 0 else { return nil }
        return (format ?? tracker.effectiveDisplayFormat).string(from: remaining)
    }

    /// When this milestone is reached, relative to `tracker`'s current streak start — or nil if
    /// there's no active streak or the milestone has already been reached as of `date`. A
    /// notification is only worth scheduling for a date this method returns.
    func fireDate(for tracker: Tracker, asOf date: Date = .now) -> Date? {
        guard let start = tracker.currentStreakStartDate else { return nil }
        let fireDate = start.addingTimeInterval(triggerDuration)
        guard fireDate > date else { return nil }
        return fireDate
    }
}

extension StreakPeriod {
    func durationString(format: TimeDisplayFormat) -> String? {
        guard let endDate else { return nil }
        return format.string(from: endDate.timeIntervalSince(startDate))
    }
}
