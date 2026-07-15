//
//  TrackerBackupFile.swift
//  Since
//

import Foundation

/// The current export/import schema version. Bump this when the DTO shapes below change in a
/// way older readers can't handle, and teach `TrackerImporter` how to read old versions forward.
let currentBackupSchemaVersion = 1

struct TrackerBackupFile: Codable {
    var schemaVersion: Int
    var trackers: [TrackerExportDTO]
}

struct TrackerExportDTO: Codable {
    var id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var category: String?
    var createdDate: Date
    var displayFormatOverride: TimeDisplayFormat?
    var streakPeriods: [StreakPeriodDTO]
    var milestones: [MilestoneDTO]
}

struct StreakPeriodDTO: Codable {
    var id: UUID
    var startDate: Date
    var endDate: Date?
    var note: String?
}

/// Deliberately has no `notificationIdentifier` field — those are device-local pending
/// notification requests and always get regenerated after import, never carried across.
struct MilestoneDTO: Codable {
    var id: UUID
    var label: String
    var triggerDuration: TimeInterval
}

enum TrackerBackupCoding {
    static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
