//
//  NotificationScheduler.swift
//  Since
//

import Foundation
import UserNotifications

enum NotificationScheduler {
    /// Schedules a local notification for `milestone`, replacing any existing pending request for
    /// it. No-ops (and clears `notificationIdentifier`) if there's no active streak, the milestone
    /// is already reached, or notifications aren't authorized — see `Milestone.fireDate(for:asOf:)`.
    static func schedule(_ milestone: Milestone, for tracker: Tracker) async {
        cancel(milestone)

        guard let fireDate = milestone.fireDate(for: tracker) else { return }

        let settings = await UNUserNotificationCenter.current().notificationSettings()
        guard settings.authorizationStatus == .authorized
            || settings.authorizationStatus == .provisional
            || settings.authorizationStatus == .ephemeral
        else { return }

        let content = UNMutableNotificationContent()
        content.title = tracker.name
        content.body = "You've reached your \(milestone.label) milestone!"
        content.sound = .default

        let identifier = milestone.id.uuidString
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: fireDate.timeIntervalSinceNow,
            repeats: false
        )
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
            milestone.notificationIdentifier = identifier
        } catch {
            milestone.notificationIdentifier = nil
        }
    }

    /// Cancels any pending notification for `milestone` and clears its stored identifier.
    static func cancel(_ milestone: Milestone) {
        if let identifier = milestone.notificationIdentifier {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        }
        milestone.notificationIdentifier = nil
    }

    /// Cancels and reschedules every milestone on `tracker` against its current streak start —
    /// used after a reset, after bulk milestone edits, and when notification permission is newly
    /// granted.
    static func rescheduleAll(for tracker: Tracker) async {
        for milestone in tracker.milestones {
            await schedule(milestone, for: tracker)
        }
    }

    /// Cancels every pending notification for `tracker`'s milestones — used before the tracker is
    /// deleted.
    static func cancelAll(for tracker: Tracker) {
        for milestone in tracker.milestones {
            cancel(milestone)
        }
    }
}
