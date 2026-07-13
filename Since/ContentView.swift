//
//  ContentView.swift
//  Since
//
//  Created by Dexter Darwich on 2026-07-02.
//

import SwiftUI
import SwiftData
import WidgetKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var trackers: [Tracker]

    @State private var isPresentingNewTrackerSheet = false
    @State private var isPresentingSettingsSheet = false
    @State private var selectedTracker: Tracker?

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTracker) {
                ForEach(trackers) { tracker in
                    HeroCardView(tracker: tracker)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .tag(tracker)
                }
                .onDelete(perform: deleteTrackers)
            }
            .listStyle(.plain)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isPresentingSettingsSheet = true
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
                ToolbarItem {
                    Button {
                        isPresentingNewTrackerSheet = true
                    } label: {
                        Label("Add Tracker", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingNewTrackerSheet) {
                TrackerEditSheet(tracker: nil)
            }
            .sheet(isPresented: $isPresentingSettingsSheet) {
                SettingsView()
            }
            .onChange(of: isPresentingNewTrackerSheet) { _, isPresented in
                if !isPresented { WidgetCenter.shared.reloadAllTimelines() }
            }
        } detail: {
            if let selectedTracker {
                TrackerDetailView(tracker: selectedTracker)
            } else {
                Text("Select a tracker")
            }
        }
    }

    private func deleteTrackers(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let tracker = trackers[index]
                if selectedTracker == tracker { selectedTracker = nil }
                NotificationScheduler.cancelAll(for: tracker)
                modelContext.delete(tracker)
            }
        }
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Tracker.self, inMemory: true)
}
