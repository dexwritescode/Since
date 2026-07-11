//
//  SinceWidget.swift
//  SinceWidget
//

import WidgetKit
import SwiftUI
import SwiftData

struct TrackerSnapshot {
    let name: String
    let icon: String
    let colorHex: String
    let elapsedText: String
    let startDateText: String?
    let milestoneText: String?
    let milestoneProgress: Double?

    init(tracker: Tracker, asOf date: Date) {
        let format = tracker.effectiveDisplayFormat
        name = tracker.name
        icon = tracker.icon
        colorHex = tracker.colorHex
        elapsedText = tracker.elapsedTimeString(asOf: date, format: format) ?? "—"
        startDateText = tracker.currentStreakStartDate.map {
            "Since \($0.formatted(date: .abbreviated, time: .omitted))"
        }

        if let milestone = tracker.nextMilestone(asOf: date) {
            milestoneText = milestone.remainingTimeString(from: tracker, asOf: date, format: format).map {
                "Next: \(milestone.label) — \($0) left"
            }
            if let elapsed = tracker.elapsedTimeInterval(asOf: date), milestone.triggerDuration > 0 {
                milestoneProgress = min(1, max(0, elapsed / milestone.triggerDuration))
            } else {
                milestoneProgress = nil
            }
        } else {
            milestoneText = nil
            milestoneProgress = nil
        }
    }

    private init(
        name: String,
        icon: String,
        colorHex: String,
        elapsedText: String,
        startDateText: String?,
        milestoneText: String?,
        milestoneProgress: Double?
    ) {
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.elapsedText = elapsedText
        self.startDateText = startDateText
        self.milestoneText = milestoneText
        self.milestoneProgress = milestoneProgress
    }

    static let placeholder = TrackerSnapshot(
        name: "Smoke Free",
        icon: "flame.fill",
        colorHex: "#4F8EF7",
        elapsedText: "12 days",
        startDateText: "Since Jun 28",
        milestoneText: "Next: 2 Weeks — 2 days left",
        milestoneProgress: 0.85
    )
}

struct SinceWidgetEntry: TimelineEntry {
    enum Content {
        case noSelection
        case tracker(TrackerSnapshot)
    }

    let date: Date
    let content: Content
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SinceWidgetEntry {
        SinceWidgetEntry(date: .now, content: .tracker(.placeholder))
    }

    func snapshot(for configuration: SelectTrackerIntent, in context: Context) async -> SinceWidgetEntry {
        let now = Date.now
        guard let tracker = resolveTracker(configuration) else {
            return SinceWidgetEntry(date: now, content: .noSelection)
        }
        return SinceWidgetEntry(date: now, content: .tracker(TrackerSnapshot(tracker: tracker, asOf: now)))
    }

    func timeline(for configuration: SelectTrackerIntent, in context: Context) async -> Timeline<SinceWidgetEntry> {
        let now = Date.now
        guard let tracker = resolveTracker(configuration) else {
            let entry = SinceWidgetEntry(date: now, content: .noSelection)
            return Timeline(entries: [entry], policy: .after(now.addingTimeInterval(60 * 60)))
        }

        let entry = SinceWidgetEntry(date: now, content: .tracker(TrackerSnapshot(tracker: tracker, asOf: now)))

        let minimumReload = now.addingTimeInterval(5 * 60)
        let format = tracker.effectiveDisplayFormat
        let reloadDate = tracker.nextDisplayChangeDate(after: now, format: format)
            .map { max($0, minimumReload) } ?? now.addingTimeInterval(60 * 60)

        return Timeline(entries: [entry], policy: .after(reloadDate))
    }

    // Widgets run in a separate process and need their own ModelContext against the shared App
    // Group store — see SharedModelContainer's docs for why the app's container can't be reused.
    private func resolveTracker(_ configuration: SelectTrackerIntent) -> Tracker? {
        guard let id = configuration.tracker?.id else { return nil }
        let context = ModelContext(SharedModelContainer.shared)
        let descriptor = FetchDescriptor<Tracker>(predicate: #Predicate { $0.id == id })
        return try? context.fetch(descriptor).first
    }
}

struct SinceWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SinceWidgetEntry

    var body: some View {
        switch entry.content {
        case .noSelection:
            noSelectionView
        case .tracker(let snapshot):
            if family == .systemMedium {
                MediumTrackerView(snapshot: snapshot)
            } else {
                SmallTrackerView(snapshot: snapshot)
            }
        }
    }

    private var noSelectionView: some View {
        VStack(spacing: 6) {
            Image(systemName: "hourglass")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Select a Tracker")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct SmallTrackerView: View {
    let snapshot: TrackerSnapshot

    var body: some View {
        let tint = Color(hex: snapshot.colorHex)

        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: snapshot.icon)
                    .font(.caption)
                    .foregroundStyle(tint)
                Text(snapshot.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Text(snapshot.elapsedText)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MediumTrackerView: View {
    let snapshot: TrackerSnapshot

    var body: some View {
        let tint = Color(hex: snapshot.colorHex)

        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: snapshot.icon)
                    .font(.headline)
                    .foregroundStyle(tint)
                Text(snapshot.name)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
            }

            Text(snapshot.elapsedText)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if let startDateText = snapshot.startDateText {
                Text(startDateText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let milestoneText = snapshot.milestoneText {
                Text(milestoneText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if let progress = snapshot.milestoneProgress {
                ProgressBar(progress: progress, tint: tint)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ProgressBar: View {
    let progress: Double
    let tint: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(tint.opacity(0.2))
                Capsule().fill(tint).frame(width: geometry.size.width * progress)
            }
        }
        .frame(height: 6)
    }
}

struct SinceWidget: Widget {
    let kind: String = "SinceWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectTrackerIntent.self, provider: Provider()) { entry in
            SinceWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    backgroundTint(for: entry)
                }
        }
        .configurationDisplayName("Since")
        .description("Shows time since a tracker started.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }

    @ViewBuilder
    private func backgroundTint(for entry: SinceWidgetEntry) -> some View {
        switch entry.content {
        case .noSelection:
            Color(.systemBackground)
        case .tracker(let snapshot):
            Color(hex: snapshot.colorHex).opacity(0.15)
        }
    }
}

#Preview(as: .systemSmall) {
    SinceWidget()
} timeline: {
    SinceWidgetEntry(date: .now, content: .tracker(.placeholder))
    SinceWidgetEntry(date: .now, content: .noSelection)
}

#Preview(as: .systemMedium) {
    SinceWidget()
} timeline: {
    SinceWidgetEntry(date: .now, content: .tracker(.placeholder))
}
