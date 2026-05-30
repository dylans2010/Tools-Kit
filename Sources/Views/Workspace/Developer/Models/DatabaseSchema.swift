import Foundation

public struct DatabaseSchema: Identifiable, Codable, Hashable {
    public var id: UUID
    public var appID: UUID
    public var tableName: String
    public var columns: [String]
    public var version: Int

    public init(id: UUID = UUID(), appID: UUID, tableName: String, columns: [String], version: Int) {
        self.id = id
        self.appID = appID
        self.tableName = tableName
        self.columns = columns
        self.version = version
    }
}
