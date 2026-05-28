import SwiftUI

struct DateFormatterDevTool: DevTool {
    let id = "date-formatter"
    let name = "Date Formatter"
    let category = DevToolCategory.data
    let icon = "calendar"
    let description = "Convert dates with multiple formats, timezones, and epochs"

    func render() -> some View {
        DateFormatterView()
    }
}

struct DateFormatterView: View {
    @StateObject private var viewModel = DateFormatterViewModel()

    var body: some View {
        Form {
            Section(header: Text("Input Date")) {
                DatePicker("Select Date", selection: $viewModel.date)
                HStack {
                    Button("Now") { viewModel.date = Date() }
                        .buttonStyle(.bordered).controlSize(.small)
                    Spacer()
                    LabeledContent("Unix", value: "\(Int(viewModel.date.timeIntervalSince1970))")
                        .font(.caption.monospaced())
                }
            }

            Section(header: Text("Epoch Converter")) {
                HStack {
                    TextField("Unix timestamp", text: $viewModel.epochInput)
                        .keyboardType(.numberPad)
                        .font(.system(.caption, design: .monospaced))
                    Button("Convert") { viewModel.convertEpoch() }
                        .buttonStyle(.borderedProminent).controlSize(.small)
                }
                if !viewModel.epochResult.isEmpty {
                    Text(viewModel.epochResult)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section(header: Text("Custom Format")) {
                TextField("yyyy-MM-dd HH:mm:ss", text: $viewModel.formatString)
                    .font(.system(.caption, design: .monospaced))
                Text(viewModel.customFormatted)
                    .font(.headline)
                    .textSelection(.enabled)
                Button {
                    UIPasteboard.general.string = viewModel.customFormatted
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered).controlSize(.small)
            }

            Section(header: Text("Common Formats")) {
                ForEach(viewModel.commonFormats, id: \.label) { item in
                    HStack {
                        Text(item.label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 100, alignment: .leading)
                        Spacer()
                        Text(item.value)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                        Button {
                            UIPasteboard.general.string = item.value
                        } label: {
                            Image(systemName: "doc.on.doc").font(.caption2)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Section(header: Text("Timezone")) {
                Picker("Timezone", selection: $viewModel.selectedTimezone) {
                    ForEach(viewModel.timezones, id: \.self) { tz in
                        Text(tz).tag(tz)
                    }
                }
                LabeledContent("Timezone Output", value: viewModel.timezoneFormatted)
                    .font(.caption.monospaced())
            }

            Section(header: Text("Relative Time")) {
                LabeledContent("Time Ago", value: viewModel.relativeTime)
                LabeledContent("Days Since", value: "\(viewModel.daysSince)")
                LabeledContent("Day of Year", value: "\(viewModel.dayOfYear)")
                LabeledContent("Week of Year", value: "\(viewModel.weekOfYear)")
                LabeledContent("Is Leap Year", value: viewModel.isLeapYear ? "Yes" : "No")
            }
        }
    }
}

struct DateFormatItem {
    let label: String
    let value: String
}

class DateFormatterViewModel: ObservableObject {
    @Published var date = Date()
    @Published var formatString = "yyyy-MM-dd HH:mm:ss"
    @Published var epochInput = ""
    @Published var epochResult = ""
    @Published var selectedTimezone = "UTC" {
        didSet { objectWillChange.send() }
    }

    let timezones = ["UTC", "America/New_York", "America/Chicago", "America/Los_Angeles", "Europe/London", "Europe/Paris", "Asia/Tokyo", "Asia/Shanghai", "Australia/Sydney"]

    var customFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = formatString
        return formatter.string(from: date)
    }

    var commonFormats: [DateFormatItem] {
        let d = date
        return [
            DateFormatItem(label: "ISO 8601", value: ISO8601DateFormatter().string(from: d)),
            DateFormatItem(label: "RFC 2822", value: {
                let f = DateFormatter(); f.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"; return f.string(from: d)
            }()),
            DateFormatItem(label: "Short", value: {
                let f = DateFormatter(); f.dateStyle = .short; f.timeStyle = .short; return f.string(from: d)
            }()),
            DateFormatItem(label: "Medium", value: {
                let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .medium; return f.string(from: d)
            }()),
            DateFormatItem(label: "Long", value: {
                let f = DateFormatter(); f.dateStyle = .long; f.timeStyle = .long; return f.string(from: d)
            }()),
            DateFormatItem(label: "Full", value: {
                let f = DateFormatter(); f.dateStyle = .full; f.timeStyle = .full; return f.string(from: d)
            }()),
            DateFormatItem(label: "HTTP", value: {
                let f = DateFormatter(); f.dateFormat = "EEE, dd MMM yyyy HH:mm:ss 'GMT'"
                f.timeZone = TimeZone(identifier: "GMT"); return f.string(from: d)
            }()),
        ]
    }

    var timezoneFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss zzz"
        formatter.timeZone = TimeZone(identifier: selectedTimezone)
        return formatter.string(from: date)
    }

    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    var daysSince: Int {
        Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
    }

    var dayOfYear: Int {
        Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 0
    }

    var weekOfYear: Int {
        Calendar.current.component(.weekOfYear, from: date)
    }

    var isLeapYear: Bool {
        let year = Calendar.current.component(.year, from: date)
        return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
    }

    func convertEpoch() {
        guard let ts = Double(epochInput) else {
            epochResult = "Invalid timestamp"
            return
        }
        let d = Date(timeIntervalSince1970: ts > 1e12 ? ts / 1000 : ts)
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .full
        epochResult = formatter.string(from: d)
        date = d
    }
}

#Preview {
    DateFormatterView()
}
