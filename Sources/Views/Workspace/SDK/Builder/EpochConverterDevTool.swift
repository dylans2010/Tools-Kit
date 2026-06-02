import SwiftUI

struct EpochConverterDevTool: DevTool {
    let id = "epoch-converter"
    let name = "Epoch Converter"
    let category: DevToolCategory = .utilities
    let icon = "clock.arrow.2.circlepath"
    let description = "Convert Unix timestamps to human-readable dates"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Enter Unix timestamp") { input in guard let interval = TimeInterval(input) else { return "Current: \(Int(Date().timeIntervalSince1970))\nDate: \(Date().formatted())" }; let date = Date(timeIntervalSince1970: interval); return "Timestamp: \(input)\nDate: \(date.formatted(date: .complete, time: .complete))\nISO 8601: \(ISO8601DateFormatter().string(from: date))" } }
}
