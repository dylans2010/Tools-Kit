import SwiftUI

struct TimezoneConverterView: View {
    @StateObject private var backend = TimezoneConverterBackend()
    @State private var sourceSearch = ""
    @State private var targetSearch = ""

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select two timezones to see the time difference and convert specific moments.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    DatePicker("Select Source Time", selection: $backend.sourceDate)
                        .onChange(of: backend.sourceDate) { _, _ in backend.convert() }

                    HStack {
                        Button(action: { backend.sourceDate = Date(); backend.convert() }) {
                            Label("Current Time", systemImage: "clock.fill")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)

                        Spacer()

                        Button(action: {
                            backend.sourceDate = Calendar.current.date(byAdding: .day, value: 1, to: backend.sourceDate) ?? backend.sourceDate
                            backend.convert()
                        }) {
                            Label("+1 Day", systemImage: "plus.circle")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Reference Time")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(.red)
                        Picker("From", selection: $backend.sourceTimezone) {
                            ForEach(filteredTimezones(query: sourceSearch), id: \.self) { tz in
                                Text(tz.replacingOccurrences(of: "_", with: " ")).tag(tz)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    TextField("Search Source City", text: $sourceSearch)
                        .font(.caption)
                        .textFieldStyle(.roundedBorder)
                }

                HStack {
                    Spacer()
                    Button(action: backend.swap) {
                        Image(systemName: "arrow.up.arrow.down.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.green)
                        Picker("To", selection: $backend.targetTimezone) {
                            ForEach(filteredTimezones(query: targetSearch), id: \.self) { tz in
                                Text(tz.replacingOccurrences(of: "_", with: " ")).tag(tz)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    TextField("Search Target City", text: $targetSearch)
                        .font(.caption)
                        .textFieldStyle(.roundedBorder)
                }
            } header: {
                Text("Locations")
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(backend.targetDateStr)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)

                    HStack {
                        Image(systemName: "info.circle")
                            .font(.caption)
                        Text(backend.offsetDescription)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)

                    Button(action: { UIPasteboard.general.string = backend.targetDateStr }) {
                        Label("Copy Converted Time", systemImage: "doc.on.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.vertical, 8)
            } header: {
                Text("Converted Result")
            }
        }
        .navigationTitle("Timezone Converter")
    }

    private func filteredTimezones(query: String) -> [String] {
        if query.isEmpty {
            // Provide a few common ones if empty, or just return all
            return ["UTC", "GMT", "US/Pacific", "US/Eastern", "Europe/London", "Europe/Paris", "Asia/Tokyo", "Asia/Shanghai", "Australia/Sydney"] + backend.timezones.prefix(5)
        }
        return backend.timezones.filter { $0.localizedCaseInsensitiveContains(query) }
    }
}

struct TimezoneConverterTool: Tool, Sendable {
    let name = "Timezone Converter"
    let icon = "clock"
    let category = ToolCategory.conversion
    let complexity = ToolComplexity.basic
    let description = "Convert date and time between any two global timezones"
    let requiresAPI = false
    var view: AnyView { AnyView(TimezoneConverterView()) }
}
