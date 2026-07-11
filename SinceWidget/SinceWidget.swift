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
    let compactElapsedText: String
    let startDateText: String?
    let milestoneText: String?
    let milestoneProgress: Double?

    init(tracker: Tracker, asOf date: Date) {
        let format = tracker.effectiveDisplayFormat
        name = tracker.name
        icon = tracker.icon
        colorHex = tracker.colorHex
        elapsedText = tracker.elapsedTimeString(asOf: date, format: format) ?? "—"
        compactElapsedText = tracker.compactElapsedText(asOf: date) ?? "—"
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
        compactElapsedText: String,
        startDateText: String?,
        milestoneText: String?,
        milestoneProgress: Double?
    ) {
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.elapsedText = elapsedText
        self.compactElapsedText = compactElapsedText
        self.startDateText = startDateText
        self.milestoneText = milestoneText
        self.milestoneProgress = milestoneProgress
    }

    static let placeholder = TrackerSnapshot(
        name: "Smoke Free",
        icon: "flame.fill",
        colorHex: "#4F8EF7",
        elapsedText: "12 days",
        compactElapsedText: "12d",
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
        content
            .containerBackground(for: .widget) {
                backgroundTint
            }
    }

    @ViewBuilder
    private var content: some View {
        switch entry.content {
        case .noSelection:
            noSelectionView
        case .tracker(let snapshot):
            switch family {
            case .systemMedium:
                MediumTrackerView(snapshot: snapshot)
            case .accessoryCircular:
                CircularTrackerView(snapshot: snapshot)
            case .accessoryInline:
                InlineTrackerView(snapshot: snapshot)
            default:
                SmallTrackerView(snapshot: snapshot)
            }
        }
    }

    @ViewBuilder
    private var noSelectionView: some View {
        switch family {
        case .accessoryCircular:
            Image(systemName: "hourglass")
        case .accessoryInline:
            Label("Select Tracker", systemImage: "hourglass")
        default:
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

    // Lock Screen (accessory) widgets are rendered by the system in its own monochrome tint —
    // a custom background/color doesn't apply there the way it does on Home Screen widgets.
    @ViewBuilder
    private var backgroundTint: some View {
        switch family {
        case .accessoryCircular, .accessoryInline:
            EmptyView()
        default:
            switch entry.content {
            case .noSelection:
                Color(.systemBackground)
            case .tracker(let snapshot):
                Color(hex: snapshot.colorHex).opacity(0.15)
            }
        }
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

private struct CircularTrackerView: View {
    let snapshot: TrackerSnapshot

    var body: some View {
        Gauge(value: snapshot.milestoneProgress ?? 0, in: 0...1) {
            Image(systemName: snapshot.icon)
        } currentValueLabel: {
            Text(snapshot.compactElapsedText)
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .widgetAccentable()
        .privacySensitive(AppSettings.lockScreenPrivacyEnabled)
    }
}

private struct InlineTrackerView: View {
    let snapshot: TrackerSnapshot

    var body: some View {
        Label(snapshot.compactElapsedText, systemImage: snapshot.icon)
            .privacySensitive(AppSettings.lockScreenPrivacyEnabled)
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
        }
        .configurationDisplayName("Since")
        .description("Shows time since a tracker started.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryInline])
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

#Preview(as: .accessoryCircular) {
    SinceWidget()
} timeline: {
    SinceWidgetEntry(date: .now, content: .tracker(.placeholder))
    SinceWidgetEntry(date: .now, content: .noSelection)
}

#Preview(as: .accessoryInline) {
    SinceWidget()
} timeline: {
    SinceWidgetEntry(date: .now, content: .tracker(.placeholder))
    SinceWidgetEntry(date: .now, content: .noSelection)
}
