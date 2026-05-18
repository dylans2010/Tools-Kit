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
        VStack(spacing: 0) {
            DevToolHeader(
                title: "Date Formatter",
                description: "Test date formatting strings and convert timestamps into human-readable formats.",
                icon: "calendar"
            )
            .padding()

            Form {
                Section("Input Date") {
                    DatePicker("Select Date", selection: $viewModel.date)
                    LabeledContent("Timestamp", value: "\(Int(viewModel.date.timeIntervalSince1970))")
                }

                Section("Format") {
                    TextField("yyyy-MM-dd HH:mm:ss", text: $viewModel.formatString)

                    Picker("Style", selection: $viewModel.dateStyle) {
                        Text("Short").tag(DateFormatter.Style.short)
                        Text("Medium").tag(DateFormatter.Style.medium)
                        Text("Long").tag(DateFormatter.Style.long)
                        Text("Full").tag(DateFormatter.Style.full)
                    }
                }

                Section("Output") {
                    Text(viewModel.formattedDate)
                        .font(.headline)
                        .textSelection(.enabled)

                    Text(viewModel.iso8601Date)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

class DateFormatterViewModel: ObservableObject {
    @Published var date = Date()
    @Published var formatString = "yyyy-MM-dd HH:mm:ss"
    @Published var dateStyle = DateFormatter.Style.medium

    var formattedDate: String {
        let formatter = DateFormatter()
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
}
