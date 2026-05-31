import Foundation

public struct DatabaseColumn: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var type: String // e.g. TEXT, INTEGER, BLOB
    public var isIndexed: Bool

    public init(id: UUID = UUID(), name: String, type: String, isIndexed: Bool = false) {
        self.id = id
        self.name = name
        self.type = type
        self.isIndexed = isIndexed
    }
}

public struct DatabaseSchema: Identifiable, Codable, Hashable {
    public var id: UUID
    public var appID: UUID
    public var tableName: String
    public var columns: [DatabaseColumn]
    public var version: Int
    public var rowCount: Int
    public var storageSizeBytes: Int

    public init(id: UUID = UUID(), appID: UUID, tableName: String, columns: [DatabaseColumn], version: Int, rowCount: Int = 0, storageSizeBytes: Int = 0) {
        self.id = id
        self.appID = appID
        self.tableName = tableName
        self.columns = columns
        self.version = version
        self.rowCount = rowCount
        self.storageSizeBytes = storageSizeBytes
    }
}
