import SwiftUI

struct DateFormatterDevTool: DevTool {
    let id = "date-formatter"
    let name = "Date Formatter"
    let category = DevToolCategory.data
    let icon = "calendar"
    let description = "Format dates and timestamps"

    func render() -> some View {
        DateFormatterView()
    }
}

struct DateFormatterView: View {
    @StateObject private var viewModel = DateFormatterViewModel()

    var body: some View {
        Form {
            Section("Current Date") {
                LabeledContent("Now", value: viewModel.nowFormatted)
                LabeledContent("Timestamp", value: viewModel.nowTimestamp)
                Button("Refresh") { viewModel.refresh() }
            }

            Section("Custom Format") {
                TextField("yyyy-MM-dd HH:mm:ss", text: $viewModel.formatString)
                LabeledContent("Result", value: viewModel.customFormatted)
            }

            Section("ISO 8601") {
                Text(viewModel.iso8601)
                    .font(.monospaced(.caption)())
                    .textSelection(.enabled)
            }
        }
    }
}

class DateFormatterViewModel: ObservableObject {
    @Published var date = Date()
    @Published var formatString = "yyyy-MM-dd HH:mm:ss"

    var nowFormatted: String {
        let formatter = Foundation.DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }

    var nowTimestamp: String {
        "\(Int(date.timeIntervalSince1970))"
    }

    var customFormatted: String {
        let formatter = Foundation.DateFormatter()
        formatter.dateFormat = formatString
        return formatter.string(from: date)
    }

    var iso8601: String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: date)
    }

    func refresh() {
        date = Date()
    }
}
