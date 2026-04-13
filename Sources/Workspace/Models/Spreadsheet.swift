import Foundation

struct Spreadsheet: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String = "Untitled Spreadsheet"
    var rows: Int = 20
    var columns: Int = 10
    var cells: [[SpreadsheetCell]] = []
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    static func empty(name: String = "Untitled Spreadsheet", rows: Int = 20, columns: Int = 10) -> Spreadsheet {
        let cells = (0..<rows).map { _ in
            (0..<columns).map { _ in SpreadsheetCell() }
        }
        return Spreadsheet(name: name, rows: rows, columns: columns, cells: cells)
    }
}
