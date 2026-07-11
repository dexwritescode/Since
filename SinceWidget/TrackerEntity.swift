//
//  TrackerEntity.swift
//  SinceWidget
//

import AppIntents
import SwiftData
import WidgetKit

struct TrackerEntity: AppEntity {
    let id: UUID
    let name: String
    let icon: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Tracker" }
    static var defaultQuery = TrackerEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", image: .init(systemName: icon))
    }
}

extension TrackerEntity {
    init(_ tracker: Tracker) {
        id = tracker.id
        name = tracker.name
        icon = tracker.icon
    }
}

struct TrackerEntityQuery: EntityQuery {
    func entities(for identifiers: [TrackerEntity.ID]) async throws -> [TrackerEntity] {
        let identifierSet = Set(identifiers)
        return try allTrackers().filter { identifierSet.contains($0.id) }.map(TrackerEntity.init)
    }

    func suggestedEntities() async throws -> [TrackerEntity] {
        try allTrackers().map(TrackerEntity.init)
    }

    private func allTrackers() throws -> [Tracker] {
        let context = ModelContext(SharedModelContainer.shared)
        return try context.fetch(FetchDescriptor<Tracker>(sortBy: [SortDescriptor(\.createdDate)]))
    }
}
