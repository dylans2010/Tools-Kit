import SwiftUI

struct TimezoneConverterView: View {
    @StateObject private var backend = TimezoneConverterBackend()

    var body: some View {
        Form {
            Section(header: Text("Source Time")) {
                HStack {
                    Button("Now") { backend.sourceDate = Date(); backend.convert() }
                    Button("+1 Day") { backend.sourceDate = Calendar.current.date(byAdding: .day, value: 1, to: backend.sourceDate) ?? backend.sourceDate; backend.convert() }
                }
                DatePicker("Date/Time", selection: $backend.sourceDate)
                    .onChange(of: backend.sourceDate) { _ in backend.convert() }

                Picker("Source Timezone", selection: $backend.sourceTimezone) {
                    ForEach(backend.timezones, id: \.self) { tz in
                        Text(tz).tag(tz)
                    }
                }
                .onChange(of: backend.sourceTimezone) { _ in backend.convert() }
            }

            Section {
                HStack {
                    Spacer()
                    Button(action: backend.swap) {
                        Image(systemName: "arrow.up.arrow.down.circle.fill")
                            .font(.title2)
                    }
                    Spacer()
                }
            }

            Section(header: Text("Target Time")) {
                Picker("Target Timezone", selection: $backend.targetTimezone) {
                    ForEach(backend.timezones, id: \.self) { tz in
                        Text(tz).tag(tz)
                    }
                }
                .onChange(of: backend.targetTimezone) { _ in backend.convert() }

                VStack(alignment: .leading, spacing: 8) {
                    Text(backend.targetDateStr)
                        .font(.title2.bold())
                        .foregroundColor(.blue)

                    Text(backend.offsetDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button(action: { UIPasteboard.general.string = backend.targetDateStr }) {
                    Label("Copy Target Time", systemImage: "doc.on.doc")
                }
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
    let description = "Convert date and time between any two global timezones"
    let requiresAPI = false
    var view: AnyView { AnyView(TimezoneConverterView()) }
}
