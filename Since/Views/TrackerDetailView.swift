//
//  TrackerDetailView.swift
//  Since
//

import SwiftUI
import SwiftData
import WidgetKit

struct TrackerDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let tracker: Tracker

    @State private var isPresentingEditTrackerSheet = false
    @State private var isPresentingAddMilestoneSheet = false
    @State private var milestoneBeingEdited: Milestone?
    @State private var isPresentingResetSheet = false

    @AppStorage(
        AppSettings.defaultDisplayFormatKey,
        store: UserDefaults(suiteName: SharedModelContainer.appGroupIdentifier)
    )
    private var defaultDisplayFormat: TimeDisplayFormat = .smart

    private var effectiveDisplayFormat: TimeDisplayFormat {
        tracker.displayFormatOverride ?? defaultDisplayFormat
    }

    private var sortedMilestones: [Milestone] {
        tracker.milestones.sorted { $0.triggerDuration < $1.triggerDuration }
    }

    var body: some View {
        List {
            Section {
                counterHeader
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            Section("Milestones") {
                ForEach(sortedMilestones) { milestone in
                    Button {
                        milestoneBeingEdited = milestone
                    } label: {
                        milestoneRow(milestone)
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: deleteMilestones)

                Button {
                    isPresentingAddMilestoneSheet = true
                } label: {
                    Label("Add Milestone", systemImage: "plus")
                }
            }

            Section("History") {
                if tracker.pastStreakPeriods.isEmpty {
                    Text("No past streaks yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(tracker.pastStreakPeriods) { period in
                        historyRow(period)
                    }
                }
            }

            Section {
                Button(role: .destructive) {
                    isPresentingResetSheet = true
                } label: {
                    Label("Reset Streak", systemImage: "arrow.counterclockwise")
                }
            }
        }
        .navigationTitle(tracker.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem {
                if let exportDocument = try? TrackerExporter.document(for: tracker) {
                    ShareLink(
                        item: exportDocument,
                        preview: SharePreview("\(tracker.name) Export")
                    ) {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                }
            }
            ToolbarItem {
                Button {
                    isPresentingEditTrackerSheet = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }
        }
        .sheet(isPresented: $isPresentingEditTrackerSheet) {
            TrackerEditSheet(tracker: tracker)
        }
        .sheet(isPresented: $isPresentingAddMilestoneSheet) {
            MilestoneFormSheet(tracker: tracker)
        }
        .sheet(item: $milestoneBeingEdited) { milestone in
            MilestoneFormSheet(tracker: tracker, milestoneToEdit: milestone)
        }
        .sheet(isPresented: $isPresentingResetSheet) {
            ResetStreakSheet(tracker: tracker)
        }
        .onChange(of: isPresentingEditTrackerSheet) { _, presented in
            if !presented { WidgetCenter.shared.reloadAllTimelines() }
        }
        .onChange(of: isPresentingAddMilestoneSheet) { _, presented in
            if !presented { WidgetCenter.shared.reloadAllTimelines() }
        }
        .onChange(of: milestoneBeingEdited) { _, milestone in
            if milestone == nil { WidgetCenter.shared.reloadAllTimelines() }
        }
        .onChange(of: isPresentingResetSheet) { _, presented in
            if !presented { WidgetCenter.shared.reloadAllTimelines() }
        }
    }

    private var counterHeader: some View {
        let tint = Color(hex: tracker.colorHex)

        return TimelineView(.periodic(from: .now, by: 60)) { context in
            VStack(spacing: 8) {
                if let elapsed = tracker.elapsedTimeString(asOf: context.date, format: effectiveDisplayFormat) {
                    Text(elapsed)
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(tint)
                }
                if let start = tracker.currentStreakStartDate {
                    Text("Since \(start.formatted(date: .abbreviated, time: .omitted))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func milestoneRow(_ milestone: Milestone) -> some View {
        let reached = isReached(milestone)
        let tint = Color(hex: tracker.colorHex)

        return HStack(spacing: 12) {
            Image(systemName: reached ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(reached ? tint : .secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(milestone.label)
                    .foregroundStyle(.primary)
                Text(milestoneSubtitle(milestone, reached: reached))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private func milestoneSubtitle(_ milestone: Milestone, reached: Bool) -> String {
        if reached {
            return "Reached"
        } else if let remaining = milestone.remainingTimeString(from: tracker, format: effectiveDisplayFormat) {
            return "\(remaining) left"
        } else {
            return "\(Int(milestone.triggerDuration / 86400)) days"
        }
    }

    private func isReached(_ milestone: Milestone) -> Bool {
        guard let elapsed = tracker.elapsedTimeInterval() else { return false }
        return elapsed >= milestone.triggerDuration
    }

    private func historyRow(_ period: StreakPeriod) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(dateRangeText(period))
            if let duration = period.durationString(format: effectiveDisplayFormat) {
                Text(duration)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let note = period.note, !note.isEmpty {
                Text(note)
                    .font(.caption)
                    .italic()
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func dateRangeText(_ period: StreakPeriod) -> String {
        let start = period.startDate.formatted(date: .abbreviated, time: .omitted)
        guard let end = period.endDate else { return start }
        return "\(start) – \(end.formatted(date: .abbreviated, time: .omitted))"
    }

    private func deleteMilestones(at offsets: IndexSet) {
        let milestones = sortedMilestones
        for index in offsets {
            let milestone = milestones[index]
            NotificationScheduler.cancel(milestone)
            modelContext.delete(milestone)
        }
        try? modelContext.save()
    }
}

#Preview {
    let tracker = Tracker(name: "Smoking", icon: "flame.fill", colorHex: "#FF6B35")
    tracker.streakPeriods.append(StreakPeriod(startDate: .now.addingTimeInterval(-86400 * 3)))
    tracker.milestones.append(Milestone(label: "One Week", triggerDuration: 7 * 86400))

    return NavigationStack {
        TrackerDetailView(tracker: tracker)
    }
    .modelContainer(for: Tracker.self, inMemory: true)
}
