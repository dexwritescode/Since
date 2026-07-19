//
//  ImportPreviewSheet.swift
//  Since
//

import SwiftUI
import SwiftData
import WidgetKit

struct ImportPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var existingTrackers: [Tracker]

    let file: TrackerBackupFile
    var onComplete: (ImportSummary) -> Void

    @State private var resolutions: [UUID: ConflictResolution] = [:]

    private var plan: ImportPlan {
        TrackerImporter.plan(for: file, existing: existingTrackers)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(plan.items) { item in
                    row(for: item)
                }
            }
            .navigationTitle("Import Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import", action: performImport)
                        .accessibilityIdentifier("Confirm Import")
                }
            }
        }
    }

    private func row(for item: ImportPlanItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: item.dto.icon)
                    .foregroundStyle(Color(hex: item.dto.colorHex))
                Text(item.dto.name)
                    .fontWeight(.medium)
                Spacer()
                if !item.isConflict {
                    Text("New")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text("\(item.dto.milestones.count) milestones · \(item.dto.streakPeriods.count) streak periods")
                .font(.caption)
                .foregroundStyle(.secondary)

            if item.isConflict {
                Text("Already exists on this device")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("Conflict Resolution", selection: binding(for: item.id)) {
                    ForEach(ConflictResolution.allCases, id: \.self) { resolution in
                        Text(resolution.label).tag(resolution)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("Conflict Resolution: \(item.dto.name)")
            }
        }
        .padding(.vertical, 4)
    }

    private func binding(for id: UUID) -> Binding<ConflictResolution> {
        Binding(
            get: { resolutions[id, default: .skip] },
            set: { resolutions[id] = $0 }
        )
    }

    private func performImport() {
        let currentPlan = plan
        let summary = TrackerImporter.commit(currentPlan, resolutions: resolutions, into: modelContext)
        try? modelContext.save()

        let allTrackers = (try? modelContext.fetch(FetchDescriptor<Tracker>())) ?? []
        Task {
            for tracker in allTrackers {
                await NotificationScheduler.rescheduleAll(for: tracker)
            }
            WidgetCenter.shared.reloadAllTimelines()
        }

        onComplete(summary)
        dismiss()
    }
}
