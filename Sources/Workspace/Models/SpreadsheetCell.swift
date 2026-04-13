import Foundation

struct SpreadsheetCell: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var value: String = ""
    var computedValue: String = ""
    var formula: String? = nil

    var displayValue: String {
        formula != nil ? computedValue : value
    }
}
