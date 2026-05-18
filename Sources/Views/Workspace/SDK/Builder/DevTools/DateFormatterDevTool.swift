import SwiftUI

struct DateFormatterDevToolImpl: DevTool {
    let id = UUID()
    let name = "Date Formatter"
    let category: DevToolCategory = .data
    let icon = "calendar.badge.clock"
    let description = "Format dates with custom patterns"
    func render() -> some View { DateFormatterDevToolView() }
}

struct DateFormatterDevToolView: View {
    @State private var selectedDate = Date()
    @State private var formatString = "yyyy-MM-dd HH:mm:ss"
    @State private var customFormats = [
        "yyyy-MM-dd", "MM/dd/yyyy", "dd MMM yyyy",
        "yyyy-MM-dd HH:mm:ss", "EEEE, MMMM d, yyyy",
        "h:mm a", "HH:mm:ss Z", "ISO8601"
    ]

    var body: some View {
        Form {
            Section("Date") {
                DatePicker("Select", selection: $selectedDate)
            }
            Section("Custom Format") {
                TextField("Format string", text: $formatString)
                    .font(.system(.body, design: .monospaced))
                    .autocorrectionDisabled()
                Text(formattedDate(formatString))
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .foregroundStyle(.accent)
            }
            Section("Common Formats") {
                ForEach(customFormats, id: \.self) { fmt in
                    LabeledContent {
                        Text(formattedDate(fmt))
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                    } label: {
                        Text(fmt).font(.caption)
                    }
                }
            }
            Section("Timestamps") {
                LabeledContent("Unix (seconds)", value: "\(Int(selectedDate.timeIntervalSince1970))")
                LabeledContent("Unix (ms)", value: "\(Int(selectedDate.timeIntervalSince1970 * 1000))")
            }
        }
        .navigationTitle("Date Formatter")
    }
    private func formattedDate(_ format: String) -> String {
        if format == "ISO8601" {
            return ISO8601DateFormatter().string(from: selectedDate)
        }
        let f = Foundation.DateFormatter()
        f.dateFormat = format
        return f.string(from: selectedDate)
    }
}
