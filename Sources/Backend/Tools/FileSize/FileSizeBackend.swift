import Foundation

class FileSizeBackend: ObservableObject {
    @Published var inputAmount = "1.0"
    @Published var inputUnit: SizeUnit = .megabytes
    @Published var results: [String: String] = [:]

    enum SizeUnit: String, CaseIterable, Identifiable {
        case bytes = "Bytes"
        case kilobytes = "KB"
        case megabytes = "MB"
        case gigabytes = "GB"
        case terabytes = "TB"

        var id: String { self.rawValue }

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

        var newResults: [String: String] = [:]
        for unit in SizeUnit.allCases {
            let value = bytes / unit.multiplier
            newResults[unit.rawValue] = format(value)
        }
        self.results = newResults
    }

    private func format(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 4
        formatter.minimumFractionDigits = 0
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
}
