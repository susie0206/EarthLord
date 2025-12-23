//
//  Item.swift
//  EarthLord
//
//  Created by 快乐一家人 on 2025/12/23.
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
