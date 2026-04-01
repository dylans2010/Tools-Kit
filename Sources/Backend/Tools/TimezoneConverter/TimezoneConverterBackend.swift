import Foundation

class TimezoneConverterBackend: ObservableObject {
    @Published var sourceTimezone = "UTC"
    @Published var targetTimezone = "Local"
    @Published var sourceDate = Date()
    @Published var targetDateStr = ""

    let timezones = TimeZone.knownTimeZoneIdentifiers

    func convert() {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: targetTimezone) ?? TimeZone.current
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        targetDateStr = formatter.string(from: sourceDate)
    }
}
