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
    @State private var trackerBeingEdited: Tracker?

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(trackers) { tracker in
                    Button {
                        trackerBeingEdited = tracker
                    } label: {
                        HeroCardView(tracker: tracker)
                    }
                    .buttonStyle(.plain)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                }
                .onDelete(perform: deleteTrackers)
            }
            .listStyle(.plain)
            .toolbar {
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
            .sheet(item: $trackerBeingEdited) { tracker in
                TrackerEditSheet(tracker: tracker)
            }
            .onChange(of: isPresentingNewTrackerSheet) { _, isPresented in
                if !isPresented { WidgetCenter.shared.reloadAllTimelines() }
            }
            .onChange(of: trackerBeingEdited) { _, tracker in
                if tracker == nil { WidgetCenter.shared.reloadAllTimelines() }
            }
        } detail: {
            Text("Select a tracker")
        }
    }

    private func deleteTrackers(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(trackers[index])
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
