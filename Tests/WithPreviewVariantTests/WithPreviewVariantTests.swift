import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(WithPreviewVariantMacros)
import WithPreviewVariantMacros

let testMacros: [String: Macro.Type] = [
    "WithPreviewVariant": WithPreviewVariantMacro.self,
]
#endif

final class WithPreviewVariantTests: XCTestCase {
    func testMacro() throws {
        #if canImport(WithPreviewVariantMacros)
        assertMacroExpansion(
            """
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
              
              @Relationship(deleteRule: .cascade, inverse: \\ItemUpdateRecord.item)
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
              @Relationship var item: Item
              
              init(id: UUID = UUID(), item: Item, date: Date = Date()) {
                self.id = id
                self.item = item
                self.date = date
              }
            }

            """,
            expandedSource: """
            enum ItemColor: Codable {
              case red, green, blue
            }@Model
            class Item {
              var id: UUID = UUID()
              var name: String = ""
              var color: ItemColor = ItemColor.blue
              @Attribute(.externalStorage) var imageData: Data?
              var createdAt: Date = Date()
              var lastUpdateAt: Date?
              var isPinned: Bool = false
              
              @Relationship(deleteRule: .cascade, inverse: \\ItemUpdateRecord.item)
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
            
            protocol ItemProtocol {
              associatedtype ItemUpdateRecord: ItemUpdateRecordProtocol
            
              var id: UUID  {
                  get
                  set
              }
              var name: String  {
                  get
                  set
              }
              var color: ItemColor  {
                  get
                  set
              }
              var imageData: Data? {
                  get
                  set
              }
              var createdAt: Date  {
                  get
                  set
              }
              var lastUpdateAt: Date? {
                  get
                  set
              }
              var isPinned: Bool  {
                  get
                  set
              }
              var records: [ItemUpdateRecord]? {
                  get
                  set
              }
            }
            
            struct PreviewItem: ItemProtocol {
              var id: UUID = UUID()
              var name: String = ""
              var color: ItemColor = ItemColor.blue
              var imageData: Data?
              var createdAt: Date = Date()
              var lastUpdateAt: Date?
              var isPinned: Bool = false
              var records: [PreviewItemUpdateRecord]?
            
            
              init(
                id: UUID = UUID(),
                name: String,
                color: ItemColor = .blue,
                imageData: Data? = nil,
                createdAt: Date = Date(),
                lastUpdateAt: Date? = nil,
                records: [PreviewItemUpdateRecord] = [],
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
            }@Model
            class ItemUpdateRecord {
              var id: UUID = UUID()
              var date: Date = Date()
              @Relationship var item: Item
              
              init(id: UUID = UUID(), item: Item, date: Date = Date()) {
                self.id = id
                self.item = item
                self.date = date
              }
            }
            
            protocol ItemUpdateRecordProtocol {
              associatedtype Item: ItemProtocol
            
              var id: UUID  {
                  get
                  set
              }
              var date: Date  {
                  get
                  set
              }
              var item: Item {
                  get
                  set
              }
            }
            
            struct PreviewItemUpdateRecord: ItemUpdateRecordProtocol {
              var id: UUID = UUID()
              var date: Date = Date()
              var item: PreviewItem
            
            
              init(id: UUID = UUID(), item: PreviewItem, date: Date = Date()) {
                self.id = id
                self.item = item
                self.date = date
              }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
