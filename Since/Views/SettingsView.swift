//
//  SettingsView.swift
//  Since
//

import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var trackers: [Tracker]

    @AppStorage(
        AppSettings.defaultDisplayFormatKey,
        store: UserDefaults(suiteName: SharedModelContainer.appGroupIdentifier)
    )
    private var defaultDisplayFormat: TimeDisplayFormat = .smart
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        NavigationStack {
            Form {
                Section("Display") {
                    Picker("Default Time Format", selection: $defaultDisplayFormat) {
                        ForEach(TimeDisplayFormat.allCases, id: \.self) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                    .accessibilityIdentifier("Default Time Format")
                }

                Section {
                    HStack {
                        Text("Milestone Notifications")
                        Spacer()
                        Text(notificationStatusText)
                            .foregroundStyle(.secondary)
                    }

                    if notificationStatus == .denied {
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                    } else if notificationStatus == .notDetermined {
                        Button("Enable Notifications") {
                            requestNotificationAuthorization()
                        }
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Notifications are used for milestone alerts. Enabling this here only grants permission — scheduling milestone alerts is separate.")
                }

                Section {
                    if let exportDocument = try? TrackerExporter.document(forAll: trackers) {
                        ShareLink(
                            item: exportDocument,
                            preview: SharePreview("Since Export")
                        ) {
                            Label("Export All Trackers", systemImage: "square.and.arrow.up")
                        }
                    }
                } header: {
                    Text("Backup")
                } footer: {
                    Text("Exports every tracker, its milestones, and its full streak history as a single JSON file you can save or send anywhere.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                await refreshNotificationStatus()
            }
        }
    }

    private var notificationStatusText: String {
        switch notificationStatus {
        case .authorized, .provisional, .ephemeral:
            "Enabled"
        case .denied:
            "Disabled"
        case .notDetermined:
            "Not Enabled"
        @unknown default:
            "Unknown"
        }
    }

    private func requestNotificationAuthorization() {
        Task {
            _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            await refreshNotificationStatus()
            for tracker in trackers {
                await NotificationScheduler.rescheduleAll(for: tracker)
            }
        }
    }

    private func refreshNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationStatus = settings.authorizationStatus
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: Tracker.self, inMemory: true)
}
