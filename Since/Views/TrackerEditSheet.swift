//
//  TrackerEditSheet.swift
//  Since
//

import SwiftUI
import SwiftData

struct MilestoneDraft: Identifiable, Equatable {
    var id: UUID
    var label: String
    var days: Int
}

extension Tracker {
    /// Diffs `drafts` against `tracker.milestones`, matching by id: existing milestones are
    /// updated in place, unmatched drafts become new milestones, and existing milestones with
    /// no matching draft are deleted. Drafts with a blank label are dropped silently.
    static func reconcileMilestones(on tracker: Tracker, with drafts: [MilestoneDraft], in context: ModelContext) {
        let validDrafts = drafts.filter { !$0.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let draftIDs = Set(validDrafts.map(\.id))

        let existingMilestones = Array(tracker.milestones)
        let existingByID = Dictionary(uniqueKeysWithValues: existingMilestones.map { ($0.id, $0) })

        for milestone in existingMilestones where !draftIDs.contains(milestone.id) {
            context.delete(milestone)
        }

        for draft in validDrafts {
            let label = draft.label.trimmingCharacters(in: .whitespacesAndNewlines)
            let duration = TimeInterval(draft.days) * 86400

            if let existing = existingByID[draft.id] {
                existing.label = label
                existing.triggerDuration = duration
            } else {
                let milestone = Milestone(id: draft.id, label: label, triggerDuration: duration)
                tracker.milestones.append(milestone)
            }
        }
    }
}

struct TrackerEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private var tracker: Tracker?

    @State private var name: String
    @State private var icon: String
    @State private var color: Color
    @State private var displayFormatOverride: TimeDisplayFormat?
    @State private var milestoneDrafts: [MilestoneDraft]

    init(tracker: Tracker?) {
        self.tracker = tracker
        _name = State(initialValue: tracker?.name ?? "")
        _icon = State(initialValue: tracker?.icon ?? TrackerIcon.curated[0])
        _color = State(initialValue: Color(hex: tracker?.colorHex ?? "#4F8EF7"))
        _displayFormatOverride = State(initialValue: tracker?.displayFormatOverride)
        _milestoneDrafts = State(initialValue: (tracker?.milestones ?? []).map {
            MilestoneDraft(id: $0.id, label: $0.label, days: max(1, Int($0.triggerDuration / 86400)))
        })
    }

    private var isEditing: Bool { tracker != nil }

    private var isNameValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Tracker name", text: $name)
                }

                Section("Icon") {
                    IconPickerView(selection: $icon, tintColor: color)
                }

                Section("Color") {
                    ColorPicker("Color", selection: $color, supportsOpacity: false)
                }

                Section("Time Format") {
                    Picker("Time Format", selection: $displayFormatOverride) {
                        Text("Default (Settings)").tag(Optional<TimeDisplayFormat>.none)
                        ForEach(TimeDisplayFormat.allCases, id: \.self) { format in
                            Text(format.displayName).tag(Optional(format))
                        }
                    }
                }

                Section("Milestones") {
                    ForEach($milestoneDrafts) { $draft in
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Label", text: $draft.label)
                            MilestonePresetPicker(days: $draft.days, label: $draft.label)
                            HStack {
                                Spacer()
                                DayCountStepper(days: $draft.days)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { offsets in
                        milestoneDrafts.remove(atOffsets: offsets)
                    }

                    Button {
                        milestoneDrafts.append(MilestoneDraft(id: UUID(), label: "", days: 7))
                    } label: {
                        Label("Add Milestone", systemImage: "plus")
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Tracker" : "New Tracker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!isNameValid)
                }
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedTracker: Tracker

        if let tracker {
            resolvedTracker = tracker
            resolvedTracker.name = trimmedName
            resolvedTracker.icon = icon
            resolvedTracker.colorHex = color.hexString
            resolvedTracker.displayFormatOverride = displayFormatOverride
        } else {
            resolvedTracker = Tracker(
                name: trimmedName,
                icon: icon,
                colorHex: color.hexString,
                displayFormatOverride: displayFormatOverride
            )
            resolvedTracker.streakPeriods.append(StreakPeriod())
            modelContext.insert(resolvedTracker)
        }

        Tracker.reconcileMilestones(on: resolvedTracker, with: milestoneDrafts, in: modelContext)

        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    TrackerEditSheet(tracker: nil)
        .modelContainer(for: Tracker.self, inMemory: true)
}
