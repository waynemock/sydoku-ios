//
//  Item.swift
//  Sydoku
//
//  Created by Wayne Mock on 12/14/25.
//

import Foundation
import SwiftData

/// A SwiftData model representing a timestamped item.
///
/// This is a template model class created by Xcode. Consider customizing
/// or removing this class based on your app's specific data model needs.
@Model
final class Item {
    /// The timestamp when this item was created or last modified.
    var timestamp: Date = Date()
    
    /// Creates a new item with the specified timestamp.
    ///
    /// - Parameter timestamp: The date and time for this item.
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
