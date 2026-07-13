//
//  ResetStreakSheet.swift
//  Since
//

import SwiftUI
import SwiftData

struct ResetStreakSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let tracker: Tracker

    @State private var note: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("This ends your current streak and starts a new one. Past streaks are kept in your history.")
                        .foregroundStyle(.secondary)
                }
                Section("Note (optional)") {
                    TextField("Reason for resetting", text: $note, axis: .vertical)
                }
            }
            .navigationTitle("Reset Streak")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Reset", role: .destructive, action: reset)
                }
            }
        }
    }

    private func reset() {
        Tracker.resetStreak(on: tracker, note: note)
        try? modelContext.save()

        Task {
            await NotificationScheduler.rescheduleAll(for: tracker)
        }

        dismiss()
    }
}

#Preview {
    ResetStreakSheet(tracker: Tracker(name: "Smoking", icon: "flame.fill", colorHex: "#FF6B35"))
        .modelContainer(for: Tracker.self, inMemory: true)
}
