//
//  Milestone.swift
//  Since
//

import Foundation
import SwiftData

@Model
final class Milestone {
    var id: UUID
    var label: String
    var triggerDuration: TimeInterval
    var notificationIdentifier: String?
    var tracker: Tracker?

    init(
        id: UUID = UUID(),
        label: String,
        triggerDuration: TimeInterval,
        notificationIdentifier: String? = nil
    ) {
        self.id = id
        self.label = label
        self.triggerDuration = triggerDuration
        self.notificationIdentifier = notificationIdentifier
    }
}
