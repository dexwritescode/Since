//
//  SettingsView.swift
//  Since
//

import SwiftUI
import SwiftData
import UserNotifications
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var trackers: [Tracker]

    @AppStorage(
        AppSettings.defaultDisplayFormatKey,
        store: UserDefaults(suiteName: SharedModelContainer.appGroupIdentifier)
    )
    private var defaultDisplayFormat: TimeDisplayFormat = .smart
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

    @State private var isPresentingFileImporter = false
    @State private var isPresentingImportPreview = false
    @State private var parsedImportFile: TrackerBackupFile?
    @State private var importErrorMessage: String?
    @State private var importSummary: ImportSummary?

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

                    Button {
                        isPresentingFileImporter = true
                    } label: {
                        Label("Import", systemImage: "square.and.arrow.down")
                    }
                } header: {
                    Text("Backup")
                } footer: {
                    Text("Exports every tracker, its milestones, and its full streak history as a single JSON file you can save or send anywhere. Importing shows a preview before anything is added.")
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
            .fileImporter(isPresented: $isPresentingFileImporter, allowedContentTypes: [.json]) { result in
                handleFileImportResult(result)
            }
            .sheet(isPresented: $isPresentingImportPreview) {
                if let parsedImportFile {
                    ImportPreviewSheet(file: parsedImportFile) { summary in
                        importSummary = summary
                    }
                }
            }
            .alert(
                "Couldn't Import File",
                isPresented: Binding(
                    get: { importErrorMessage != nil },
                    set: { if !$0 { importErrorMessage = nil } }
                )
            ) {
                Button("OK") { importErrorMessage = nil }
            } message: {
                Text(importErrorMessage ?? "")
            }
            .alert(
                "Import Complete",
                isPresented: Binding(
                    get: { importSummary != nil },
                    set: { if !$0 { importSummary = nil } }
                )
            ) {
                Button("OK") { importSummary = nil }
            } message: {
                Text(importSummaryText)
            }
        }
    }

    private var importSummaryText: String {
        guard let importSummary else { return "" }
        return "Imported \(importSummary.imported), merged \(importSummary.merged), overwritten \(importSummary.overwritten), skipped \(importSummary.skipped)."
    }

    private func handleFileImportResult(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing { url.stopAccessingSecurityScopedResource() }
            }

            let data = try Data(contentsOf: url)
            parsedImportFile = try TrackerImporter.parse(data)
            isPresentingImportPreview = true
        } catch {
            importErrorMessage = error.localizedDescription
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
