import Foundation

class FileSizeBackend: ObservableObject {
    @Published var inputAmount = "1.0"
    @Published var inputUnit: SizeUnit = .megabytes
    @Published var result = ""

    enum SizeUnit: String, CaseIterable {
        case bytes = "Bytes"
        case kilobytes = "KB"
        case megabytes = "MB"
        case gigabytes = "GB"
        case terabytes = "TB"

        var multiplier: Double {
            switch self {
            case .bytes: return 1
            case .kilobytes: return 1024
            case .megabytes: return 1024 * 1024
            case .gigabytes: return 1024 * 1024 * 1024
            case .terabytes: return 1024 * 1024 * 1024 * 1024
            }
        }
    }

    func convert() {
        guard let amount = Double(inputAmount) else { return }
        let bytes = amount * inputUnit.multiplier

        result = SizeUnit.allCases.map { unit in
            let value = bytes / unit.multiplier
            return String(format: "%.4f %@", value, unit.rawValue)
        }.joined(separator: "\n")
    }
}
