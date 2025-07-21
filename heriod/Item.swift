//
//  Item.swift
//  heriod
//
//  Created by JB Rubinovitz on 7/21/25.
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
