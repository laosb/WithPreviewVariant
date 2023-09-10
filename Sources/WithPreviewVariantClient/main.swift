import Foundation
import SwiftData
import SwiftUI

import WithPreviewVariant

enum ItemColor: Codable {
  case red, green, blue
}

@WithPreviewVariant @Model
class Item {
  var id: UUID = UUID()
  var name: String = ""
  var color: ItemColor = ItemColor.blue
  @Attribute(.externalStorage) var imageData: Data?
  var createdAt: Date = Date()
  var lastUpdateAt: Date?
  var isPinned: Bool = false
  
  @Relationship(deleteRule: .cascade, inverse: \ItemUpdateRecord.item)
  var records: [ItemUpdateRecord]?
  
  init(
    id: UUID = UUID(),
    name: String,
    color: ItemColor = .blue,
    imageData: Data? = nil,
    createdAt: Date = Date(),
    lastUpdateAt: Date? = nil,
    records: [ItemUpdateRecord] = [],
    isPinned: Bool = false
  ) {
    self.id = id
    self.name = name
    self.color = color
    self.imageData = imageData
    self.createdAt = createdAt
    self.lastUpdateAt = lastUpdateAt
    self.records = records
    self.isPinned = isPinned
  }
}

@WithPreviewVariant @Model
class ItemUpdateRecord {
  var id: UUID = UUID()
  var date: Date = Date()
  @InverseRelationship var item: Item
  
  init(id: UUID = UUID(), item: Item, date: Date = Date()) {
    self.id = id
    self.item = item
    self.date = date
  }
}
