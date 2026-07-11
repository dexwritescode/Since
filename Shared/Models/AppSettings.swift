//
//  AppSettings.swift
//  Since
//

import Foundation

/// App-wide settings stored in the shared App Group `UserDefaults` suite, so both the app and
/// widget extension processes read the same values.
enum AppSettings {
    static let defaultDisplayFormatKey = "defaultDisplayFormat"
    static let lockScreenPrivacyEnabledKey = "lockScreenPrivacyEnabled"

    private static let defaults: UserDefaults = {
        UserDefaults(suiteName: SharedModelContainer.appGroupIdentifier) ?? .standard
    }()

    static var defaultDisplayFormat: TimeDisplayFormat {
        get {
            guard let rawValue = defaults.string(forKey: defaultDisplayFormatKey) else { return .smart }
            return TimeDisplayFormat(rawValue: rawValue) ?? .smart
        }
        set {
            defaults.set(newValue.rawValue, forKey: defaultDisplayFormatKey)
        }
    }

    /// Whether Lock Screen widget values are marked `.privacySensitive()`. Defaults to on,
    /// consistent with this app's privacy-first stance elsewhere (e.g. Face ID lock).
    static var lockScreenPrivacyEnabled: Bool {
        get {
            guard defaults.object(forKey: lockScreenPrivacyEnabledKey) != nil else { return true }
            return defaults.bool(forKey: lockScreenPrivacyEnabledKey)
        }
        set {
            defaults.set(newValue, forKey: lockScreenPrivacyEnabledKey)
        }
    }
}
