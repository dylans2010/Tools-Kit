import SwiftUI

struct DateFormatterDevTool: DevTool {
    let id = "date-formatter"
    let name = "Date Formatter"
    let category = DevToolCategory.data
    let icon = "calendar"
    let description = "Convert between dates and strings"

    func render() -> some View {
        DateFormatterView()
    }
}

struct DateFormatterView: View {
    @StateObject private var viewModel = DateFormatterViewModel()

    var body: some View {
        List {
            Section("Source") {
                DatePicker("Date & Time", selection: $viewModel.date)

                HStack {
                    Text("Unix Timestamp")
                    Spacer()
                    TextField("Timestamp", value: $viewModel.timestamp, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numberPad)
                        .frame(width: 140)
                }

                Button("Set to Now") {
                    viewModel.date = Date()
                }
                .font(.caption)
            }

            Section("Format Configuration") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Custom Pattern").font(.caption2).foregroundStyle(.secondary)
                    TextField("e.g. EEEE, MMM d, yyyy", text: $viewModel.formatString)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Picker("Preset Style", selection: $viewModel.dateStyle) {
                    Text("Short").tag(DateFormatter.Style.short)
                    Text("Medium").tag(DateFormatter.Style.medium)
                    Text("Long").tag(DateFormatter.Style.long)
                    Text("Full").tag(DateFormatter.Style.full)
                }

                Picker("Locale", selection: $viewModel.localeIdentifier) {
                    Text("Current").tag("current")
                    Text("US (en_US)").tag("en_US")
                    Text("UK (en_GB)").tag("en_GB")
                    Text("Germany (de_DE)").tag("de_DE")
                    Text("Japan (ja_JP)").tag("ja_JP")
                }
            }

            Section("Standard Formats") {
                ResultRow(label: "Formatted Output", value: viewModel.formattedDate)
                ResultRow(label: "ISO 8601 (Strict)", value: viewModel.iso8601Date)
                ResultRow(label: "Relative Time", value: viewModel.relativeDate)
                ResultRow(label: "RFC 3339", value: viewModel.rfc3339Date)
                ResultRow(label: "Unix Timestamp", value: "\(viewModel.timestamp)")
            }

            Section("Date Calculations") {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Day of Year").font(.caption2).foregroundStyle(.secondary)
                        Text("\(viewModel.dayOfYear)").font(.headline)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Week of Year").font(.caption2).foregroundStyle(.secondary)
                        Text("\(viewModel.weekOfYear)").font(.headline)
                    }
                }

                LabeledContent("Is Weekend", value: viewModel.isWeekend ? "Yes" : "No")
                LabeledContent("Is Leap Year", value: viewModel.isLeapYear ? "Yes" : "No")
                LabeledContent("Days in Month", value: "\(viewModel.daysInMonth)")

                VStack(alignment: .leading, spacing: 8) {
                    Text("Timezone Info").font(.caption2).foregroundStyle(.secondary)
                    LabeledContent("Identifier", value: TimeZone.current.identifier)
                    LabeledContent("Abbreviation", value: TimeZone.current.abbreviation() ?? "N/A")
                    LabeledContent("GMT Offset", value: "\(TimeZone.current.secondsFromGMT() / 3600) hours")
                }
            }

            Section("Swift Code Snippet") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.swiftSnippet)
                        .font(.system(size: 9, design: .monospaced))
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(6)

                    Button {
                        UIPasteboard.general.string = viewModel.swiftSnippet
                    } label: {
                        Label("Copy Swift Code", systemImage: "doc.on.doc")
                    }
                    .controlSize(.small)
                    .buttonStyle(.bordered)
                }
            }
        }
        .navigationTitle("Date Tool")
    }
}

struct ResultRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 10, weight: .black)).foregroundStyle(.blue)
            HStack {
                Text(value)
                    .font(.system(.subheadline, design: .monospaced))
                    .textSelection(.enabled)
                Spacer()
                Button {
                    UIPasteboard.general.string = value
                } label: {
                    Image(systemName: "doc.on.doc").font(.caption)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

class DateFormatterViewModel: ObservableObject {
    @Published var date = Date()
    @Published var formatString = ""
    @Published var dateStyle = DateFormatter.Style.medium
    @Published var localeIdentifier = "current"

    var timestamp: Int {
        get { Int(date.timeIntervalSince1970) }
        set { date = Date(timeIntervalSince1970: TimeInterval(newValue)) }
    }

    var dayOfYear: Int {
        Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 0
    }

    var isLeapYear: Bool {
        let year = Calendar.current.component(.year, from: date)
        return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
    }

    var swiftSnippet: String {
        """
        let formatter = DateFormatter()
        formatter.dateFormat = "\(formatString.isEmpty ? "MMM d, yyyy" : formatString)"
        let result = formatter.string(from: Date())
        """
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        if localeIdentifier != "current" {
            formatter.locale = Locale(identifier: localeIdentifier)
        }
        if !formatString.isEmpty {
            formatter.dateFormat = formatString
        } else {
            formatter.dateStyle = dateStyle
            formatter.timeStyle = dateStyle
        }
        return formatter.string(from: date)
    }

    var iso8601Date: String {
        ISO8601DateFormatter().string(from: date)
    }

    var rfc3339Date: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }

    var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    var weekOfYear: Int {
        Calendar.current.component(.weekOfYear, from: date)
    }

    var isWeekend: Bool {
        Calendar.current.isDateInWeekend(date)
    }

    var daysInMonth: Int {
        Calendar.current.range(of: .day, in: .month, for: date)?.count ?? 0
    }
}

#Preview {
    DateFormatterView()
}
