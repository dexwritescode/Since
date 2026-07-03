//
//  Item.swift
//  Since
//
//  Created by Dexter Darwich on 2026-07-02.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
