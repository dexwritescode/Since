//
//  MilestoneFormSheet.swift
//  Since
//

import SwiftUI
import SwiftData

struct MilestoneFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let tracker: Tracker
    private var milestoneToEdit: Milestone?

    @State private var label: String
    @State private var days: Int

    init(tracker: Tracker, milestoneToEdit: Milestone? = nil) {
        self.tracker = tracker
        self.milestoneToEdit = milestoneToEdit
        _label = State(initialValue: milestoneToEdit?.label ?? "")
        _days = State(initialValue: milestoneToEdit.map { max(1, Int($0.triggerDuration / 86400)) } ?? 7)
    }

    private var isEditing: Bool { milestoneToEdit != nil }

    private var isLabelValid: Bool {
        !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Label", text: $label)
                MilestonePresetPicker(days: $days)
                HStack {
                    Text("Duration")
                    Spacer()
                    DayCountStepper(days: $days)
                }
            }
            .navigationTitle(isEditing ? "Edit Milestone" : "New Milestone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!isLabelValid)
                }
            }
        }
    }

    private func save() {
        let trimmedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
        let duration = TimeInterval(days) * 86400

        if let milestone = milestoneToEdit {
            milestone.label = trimmedLabel
            milestone.triggerDuration = duration
        } else {
            tracker.milestones.append(Milestone(label: trimmedLabel, triggerDuration: duration))
        }

        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    MilestoneFormSheet(tracker: Tracker(name: "Smoking", icon: "flame.fill", colorHex: "#FF6B35"))
        .modelContainer(for: Tracker.self, inMemory: true)
}
