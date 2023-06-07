//
//  Item.swift
//  WidgetSoundboard
//
//  Created by Leo Mehlig on 07.06.23.
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
