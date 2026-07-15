//
//  TrackerExporter.swift
//  Since
//

import Foundation
import CoreTransferable
import UniformTypeIdentifiers

struct TrackerBackupDocument: Transferable {
    let fileURL: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .json) { document in
            SentTransferredFile(document.fileURL)
        }
    }
}

enum TrackerExporter {
    static func document(for tracker: Tracker) throws -> TrackerBackupDocument {
        try document(for: [tracker], suggestedName: "Since-\(sanitized(tracker.name))-Export")
    }

    static func document(forAll trackers: [Tracker]) throws -> TrackerBackupDocument {
        try document(for: trackers, suggestedName: "Since-All-Trackers-Export")
    }

    private static func document(for trackers: [Tracker], suggestedName: String) throws -> TrackerBackupDocument {
        let file = TrackerBackupFile(
            schemaVersion: currentBackupSchemaVersion,
            trackers: trackers.map(dto(for:))
        )
        let data = try TrackerBackupCoding.encoder.encode(file)

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(suggestedName).json")
        try data.write(to: url, options: .atomic)
        return TrackerBackupDocument(fileURL: url)
    }

    static func dto(for tracker: Tracker) -> TrackerExportDTO {
        TrackerExportDTO(
            id: tracker.id,
            name: tracker.name,
            icon: tracker.icon,
            colorHex: tracker.colorHex,
            category: tracker.category,
            createdDate: tracker.createdDate,
            displayFormatOverride: tracker.displayFormatOverride,
            streakPeriods: tracker.streakPeriods.map(dto(for:)),
            milestones: tracker.milestones.map(dto(for:))
        )
    }

    private static func dto(for period: StreakPeriod) -> StreakPeriodDTO {
        StreakPeriodDTO(id: period.id, startDate: period.startDate, endDate: period.endDate, note: period.note)
    }

    private static func dto(for milestone: Milestone) -> MilestoneDTO {
        MilestoneDTO(id: milestone.id, label: milestone.label, triggerDuration: milestone.triggerDuration)
    }

    private static func sanitized(_ name: String) -> String {
        let allowed = name.map { $0.isLetter || $0.isNumber ? $0 : "-" }
        let collapsed = String(allowed).replacingOccurrences(of: "-{2,}", with: "-", options: .regularExpression)
        let trimmed = collapsed.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return trimmed.isEmpty ? "Tracker" : trimmed
    }
}
