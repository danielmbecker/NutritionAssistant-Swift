//
//  Item.swift
//  NutritionAssistant
//
//  Created by Daniel Becker on 5/20/26.
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
