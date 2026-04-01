import SwiftUI

struct TimezoneConverterView: View {
    @StateObject private var backend = TimezoneConverterBackend()

    var body: some View {
        Form {
            Section(header: Text("Source")) {
                DatePicker("Date/Time", selection: $backend.sourceDate)
                Picker("From", selection: $backend.sourceTimezone) {
                    ForEach(backend.timezones, id: \.self) { tz in
                        Text(tz).tag(tz)
                    }
                }
            }

            Section(header: Text("Target")) {
                Picker("To", selection: $backend.targetTimezone) {
                    ForEach(backend.timezones, id: \.self) { tz in
                        Text(tz).tag(tz)
                    }
                }
                Text(backend.targetDateStr)
                    .font(.headline)
            }

            Button("Convert") {
                backend.convert()
            }
        }
        .navigationTitle("Timezone Converter")
    }
}

struct TimezoneConverterTool: Tool {
    let name = "Timezone Converter"
    let icon = "clock"
    let category = ToolCategory.conversion
    let complexity = ToolComplexity.basic
    let description = "Convert between different timezones"
    let requiresAPI = false

    var view: AnyView {
        AnyView(TimezoneConverterView())
    }
}
