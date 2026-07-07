//
//  Item.swift
//  MODI
//
//  Created by 김영임 on 7/8/26.
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
