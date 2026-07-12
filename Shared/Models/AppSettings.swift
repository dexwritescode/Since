//
//  AppSettings.swift
//  Since
//

import Foundation

/// App-wide settings stored in the shared App Group `UserDefaults` suite, so both the app and
/// widget extension processes read the same values.
enum AppSettings {
    static let defaultDisplayFormatKey = "defaultDisplayFormat"

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
}
