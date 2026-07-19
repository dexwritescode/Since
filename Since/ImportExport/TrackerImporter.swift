//
//  TrackerImporter.swift
//  Since
//

import Foundation
import SwiftData

enum TrackerImportError: LocalizedError {
    case invalidJSON
    case unsupportedSchemaVersion(found: Int)

    var errorDescription: String? {
        switch self {
        case .invalidJSON:
            "This file isn't a valid Since backup."
        case .unsupportedSchemaVersion(let found):
            "This backup was made with a newer version of Since (schema \(found)) and can't be read by this version of the app."
        }
    }
}

enum ConflictResolution: CaseIterable, Hashable {
    case skip
    case merge
    case overwrite

    var label: String {
        switch self {
        case .skip: "Skip"
        case .merge: "Merge"
        case .overwrite: "Overwrite"
        }
    }
}

/// One tracker from an import file, paired with whatever existing tracker it conflicts with (if
/// any), matched by `id`.
struct ImportPlanItem: Identifiable {
    let dto: TrackerExportDTO
    let conflictingTracker: Tracker?

    var id: UUID { dto.id }
    var isConflict: Bool { conflictingTracker != nil }
}

struct ImportPlan {
    let schemaVersion: Int
    let items: [ImportPlanItem]
}

struct ImportSummary {
    var imported = 0
    var merged = 0
    var overwritten = 0
    var skipped = 0
}

enum TrackerImporter {
    static func parse(_ data: Data) throws -> TrackerBackupFile {
        let file: TrackerBackupFile
        do {
            file = try TrackerBackupCoding.decoder.decode(TrackerBackupFile.self, from: data)
        } catch {
            throw TrackerImportError.invalidJSON
        }

        guard file.schemaVersion <= currentBackupSchemaVersion else {
            throw TrackerImportError.unsupportedSchemaVersion(found: file.schemaVersion)
        }

        return file
    }

    static func plan(for file: TrackerBackupFile, existing: [Tracker]) -> ImportPlan {
        let existingByID = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
        let items = file.trackers.map { dto in
            ImportPlanItem(dto: dto, conflictingTracker: existingByID[dto.id])
        }
        return ImportPlan(schemaVersion: file.schemaVersion, items: items)
    }

    /// Commits `plan` into `context` using `resolutions` (keyed by tracker id) for conflicting
    /// items; non-conflicting items are always imported as new trackers. Returns counts for a
    /// confirmation message. Does not reschedule notifications or reload widget timelines —
    /// callers are expected to do that afterward for any tracker that changed.
    @discardableResult
    static func commit(
        _ plan: ImportPlan,
        resolutions: [UUID: ConflictResolution],
        into context: ModelContext
    ) -> ImportSummary {
        var summary = ImportSummary()

        for item in plan.items {
            guard let existingTracker = item.conflictingTracker else {
                insert(item.dto, into: context)
                summary.imported += 1
                continue
            }

            switch resolutions[item.id, default: .skip] {
            case .skip:
                summary.skipped += 1
            case .merge:
                merge(item.dto, into: existingTracker, context: context)
                summary.merged += 1
            case .overwrite:
                overwrite(existingTracker, with: item.dto, context: context)
                summary.overwritten += 1
            }
        }

        return summary
    }

    private static func insert(_ dto: TrackerExportDTO, into context: ModelContext) {
        let tracker = Tracker(
            id: dto.id,
            name: dto.name,
            icon: dto.icon,
            colorHex: dto.colorHex,
            category: dto.category,
            createdDate: dto.createdDate,
            displayFormatOverride: dto.displayFormatOverride
        )
        context.insert(tracker)

        for periodDTO in dto.streakPeriods {
            let period = StreakPeriod(
                id: periodDTO.id,
                startDate: periodDTO.startDate,
                endDate: periodDTO.endDate,
                note: periodDTO.note
            )
            period.tracker = tracker
            tracker.streakPeriods.append(period)
        }

        for milestoneDTO in dto.milestones {
            let milestone = Milestone(
                id: milestoneDTO.id,
                label: milestoneDTO.label,
                triggerDuration: milestoneDTO.triggerDuration
            )
            milestone.tracker = tracker
            tracker.milestones.append(milestone)
        }
    }

    private static func merge(_ dto: TrackerExportDTO, into tracker: Tracker, context: ModelContext) {
        let existingPeriodIDs = Set(tracker.streakPeriods.map(\.id))
        let hasActivePeriod = tracker.activeStreakPeriod != nil

        for periodDTO in dto.streakPeriods where !existingPeriodIDs.contains(periodDTO.id) {
            let isOpenPeriod = periodDTO.endDate == nil
            if isOpenPeriod && hasActivePeriod { continue }

            let period = StreakPeriod(
                id: periodDTO.id,
                startDate: periodDTO.startDate,
                endDate: periodDTO.endDate,
                note: periodDTO.note
            )
            period.tracker = tracker
            tracker.streakPeriods.append(period)
        }

        let existingMilestoneIDs = Set(tracker.milestones.map(\.id))
        for milestoneDTO in dto.milestones where !existingMilestoneIDs.contains(milestoneDTO.id) {
            let milestone = Milestone(
                id: milestoneDTO.id,
                label: milestoneDTO.label,
                triggerDuration: milestoneDTO.triggerDuration
            )
            milestone.tracker = tracker
            tracker.milestones.append(milestone)
        }
    }

    private static func overwrite(_ tracker: Tracker, with dto: TrackerExportDTO, context: ModelContext) {
        tracker.name = dto.name
        tracker.icon = dto.icon
        tracker.colorHex = dto.colorHex
        tracker.category = dto.category
        tracker.createdDate = dto.createdDate
        tracker.displayFormatOverride = dto.displayFormatOverride

        for period in tracker.streakPeriods {
            context.delete(period)
        }
        tracker.streakPeriods = []

        NotificationScheduler.cancelAll(for: tracker)
        for milestone in tracker.milestones {
            context.delete(milestone)
        }
        tracker.milestones = []

        for periodDTO in dto.streakPeriods {
            let period = StreakPeriod(
                id: periodDTO.id,
                startDate: periodDTO.startDate,
                endDate: periodDTO.endDate,
                note: periodDTO.note
            )
            period.tracker = tracker
            tracker.streakPeriods.append(period)
        }

        for milestoneDTO in dto.milestones {
            let milestone = Milestone(
                id: milestoneDTO.id,
                label: milestoneDTO.label,
                triggerDuration: milestoneDTO.triggerDuration
            )
            milestone.tracker = tracker
            tracker.milestones.append(milestone)
        }
    }
}
