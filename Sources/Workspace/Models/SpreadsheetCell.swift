import Foundation

struct SpreadsheetCell: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var value: String = ""
    var computedValue: String = ""
    var formula: String? = nil

    // Formatting
    var isBold: Bool = false
    var isItalic: Bool = false
    var textAlignment: CellAlignment = .leading
    var numberFormat: CellNumberFormat = .plain

    var displayValue: String {
        formula != nil ? computedValue : value
    }

    enum CellAlignment: String, Codable, CaseIterable {
        case leading = "Leading"
        case center = "Center"
        case trailing = "Trailing"
    }

    enum CellNumberFormat: String, Codable, CaseIterable {
        case plain = "Plain"
        case number = "Number"
        case currency = "Currency"
        case percentage = "Percentage"
        case date = "Date"
    }
}
