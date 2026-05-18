import SwiftUI

struct TimezoneConverterDevTool: DevTool {
    let id = "timezone-converter"
    let name = "Timezone Converter"
    let category = DevToolCategory.data
    let icon = "globe"
    let description = "Convert time between timezones"

    func render() -> some View {
        TimezoneConverterView()
    }
}

struct TimezoneConverterView: View {
    @StateObject private var viewModel = TimezoneConverterViewModel()

    var body: some View {
        Form {
            Section("Source Time") {
                DatePicker("Time", selection: $viewModel.sourceTime)
                Picker("Timezone", selection: $viewModel.sourceTimeZone) {
                    ForEach(TimeZone.knownTimeZoneIdentifiers, id: \.self) { id in
                        Text(id).tag(id)
                    }
                }
            }

            Section("Destination Time") {
                Picker("Timezone", selection: $viewModel.destTimeZone) {
                    ForEach(TimeZone.knownTimeZoneIdentifiers, id: \.self) { id in
                        Text(id).tag(id)
                    }
                }
                LabeledContent("Converted", value: viewModel.convertedTime)
            }
        }
    }
}

class TimezoneConverterViewModel: ObservableObject {
    @Published var sourceTime = Date()
    @Published var sourceTimeZone = TimeZone.current.identifier
    @Published var destTimeZone = "UTC"

    var convertedTime: String {
        let formatter = Foundation.DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: destTimeZone)
        return formatter.string(from: sourceTime)
    }
}
