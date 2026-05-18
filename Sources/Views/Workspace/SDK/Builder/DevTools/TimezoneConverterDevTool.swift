import SwiftUI

struct TimezoneConverterTool: DevTool {
    let id = UUID()
    let name = "Timezone Converter"
    let category: DevToolCategory = .data
    let icon = "globe.americas"
    let description = "Convert times between timezones"
    func render() -> some View { TimezoneConverterDevToolView() }
}

struct TimezoneConverterDevToolView: View {
    @State private var date = Date()
    private let zones = ["UTC", "America/New_York", "America/Chicago", "America/Denver",
                         "America/Los_Angeles", "Europe/London", "Europe/Paris",
                         "Europe/Berlin", "Asia/Tokyo", "Asia/Shanghai",
                         "Asia/Kolkata", "Australia/Sydney", "Pacific/Auckland"]

    var body: some View {
        Form {
            Section("Reference Time") {
                DatePicker("Time", selection: $date)
            }
            Section("Timezones") {
                ForEach(zones, id: \.self) { zone in
                    if let tz = TimeZone(identifier: zone) {
                        LabeledContent {
                            Text(formattedTime(in: tz)).font(.system(.caption, design: .monospaced))
                        } label: {
                            VStack(alignment: .leading) {
                                Text(zone.split(separator: "/").last.map(String.init) ?? zone).font(.subheadline)
                                Text("UTC\(offsetString(tz))").font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Timezone Converter")
    }
    private func formattedTime(in tz: TimeZone) -> String {
        let f = Foundation.DateFormatter()
        f.dateFormat = "HH:mm:ss"
        f.timeZone = tz
        return f.string(from: date)
    }
    private func offsetString(_ tz: TimeZone) -> String {
        let seconds = tz.secondsFromGMT(for: date)
        let h = seconds / 3600
        let m = abs(seconds % 3600) / 60
        return m == 0 ? (h >= 0 ? "+\(h)" : "\(h)") : String(format: "%+d:%02d", h, m)
    }
}
