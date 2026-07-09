//
//  TimeDisplayFormat.swift
//  Since
//

import Foundation

enum TimeDisplayFormat: String, Codable, CaseIterable {
    case smart
    case daysOnly
    case detailed
}

extension TimeDisplayFormat {
    var displayName: String {
        switch self {
        case .smart: "Smart"
        case .daysOnly: "Days Only"
        case .detailed: "Detailed"
        }
    }
}
