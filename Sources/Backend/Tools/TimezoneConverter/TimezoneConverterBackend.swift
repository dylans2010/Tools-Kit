import Foundation

class TimezoneConverterBackend: ObservableObject {
    @Published var sourceTimezone = TimeZone.current.identifier
    @Published var targetTimezone = "UTC"
    @Published var sourceDate = Date()
    @Published var targetDateStr = ""
    @Published var offsetDescription = ""

    let timezones = TimeZone.knownTimeZoneIdentifiers

    init() {
        convert()
    }

    func convert() {
        let formatter = DateFormatter()
        let targetTZ = TimeZone(identifier: targetTimezone) ?? TimeZone(identifier: "UTC")!
        formatter.timeZone = targetTZ
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        targetDateStr = formatter.string(from: sourceDate)

        let sourceTZ = TimeZone(identifier: sourceTimezone) ?? TimeZone.current
        let sourceOffset = sourceTZ.secondsFromGMT(for: sourceDate)
        let targetOffset = targetTZ.secondsFromGMT(for: sourceDate)
        let diff = Double(targetOffset - sourceOffset) / 3600.0

        let sign = diff >= 0 ? "+" : ""
        offsetDescription = "Target is \(sign)\(String(format: "%.1f", diff)) hours from source"
    }

    func swap() {
        let temp = sourceTimezone
        sourceTimezone = targetTimezone
        targetTimezone = temp
        convert()
    }
}
