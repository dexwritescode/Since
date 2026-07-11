//
//  AppIntent.swift
//  SinceWidget
//

import WidgetKit
import AppIntents

struct SelectTrackerIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Select Tracker" }
    static var description: IntentDescription { "Choose which tracker this widget displays." }

    @Parameter(title: "Tracker")
    var tracker: TrackerEntity?
}
