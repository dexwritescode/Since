//
//  SinceWidget.swift
//  SinceWidget
//
//  Created by Dexter Darwich on 2026-07-02.
//

import WidgetKit
import SwiftUI
import SwiftData

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), trackerCount: 0)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration, trackerCount: currentTrackerCount())
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let entry = SimpleEntry(date: Date(), configuration: configuration, trackerCount: currentTrackerCount())
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: entry.date)!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    // Temporary proof that the widget process can read the shared App Group
    // SwiftData store written by the main app; superseded once SIN-7 builds
    // the real per-tracker widget UI.
    private func currentTrackerCount() -> Int {
        let context = ModelContext(SharedModelContainer.shared)
        return (try? context.fetchCount(FetchDescriptor<Tracker>())) ?? 0
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let trackerCount: Int
}

struct SinceWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Text("Trackers")
                .font(.caption)
            Text("\(entry.trackerCount)")
                .font(.largeTitle)
        }
    }
}

struct SinceWidget: Widget {
    let kind: String = "SinceWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            SinceWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

#Preview(as: .systemSmall) {
    SinceWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: ConfigurationAppIntent(), trackerCount: 0)
    SimpleEntry(date: .now, configuration: ConfigurationAppIntent(), trackerCount: 3)
}
