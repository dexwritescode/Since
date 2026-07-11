//
//  SettingsView.swift
//  Since
//

import SwiftUI
import UserNotifications

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage(
        AppSettings.defaultDisplayFormatKey,
        store: UserDefaults(suiteName: SharedModelContainer.appGroupIdentifier)
    )
    private var defaultDisplayFormat: TimeDisplayFormat = .smart
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

    @AppStorage(
        AppSettings.lockScreenPrivacyEnabledKey,
        store: UserDefaults(suiteName: SharedModelContainer.appGroupIdentifier)
    )
    private var lockScreenPrivacyEnabled = true

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
                    Toggle("Blur Values When Locked", isOn: $lockScreenPrivacyEnabled)
                } header: {
                    Text("Lock Screen Widgets")
                } footer: {
                    Text("When enabled, tracker values on Lock Screen widgets are hidden until you unlock your device.")
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
        }
    }

    private func refreshNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationStatus = settings.authorizationStatus
    }
}

#Preview {
    SettingsView()
}
