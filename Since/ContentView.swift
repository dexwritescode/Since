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

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(trackers) { tracker in
                    NavigationLink {
                        Text(tracker.name)
                    } label: {
                        Label(tracker.name, systemImage: tracker.icon)
                    }
                }
                .onDelete(perform: deleteTrackers)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addTracker) {
                        Label("Add Tracker", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select a tracker")
        }
    }

    private func addTracker() {
        withAnimation {
            let tracker = Tracker(name: "New Tracker", icon: "flame.fill", colorHex: "#4F8EF7")
            tracker.streakPeriods.append(StreakPeriod())
            modelContext.insert(tracker)
        }
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
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
