import SwiftUI

struct TimezoneConverterDevTool: DevTool {
    let id = "timezone-converter"
    let name = "Timezone Converter"
    let category = DevToolCategory.data
    let icon = "clock.badge.checkmark"
    let description = "Convert times between different timezones"

    func render() -> some View {
        TimezoneConverterDevToolView()
    }
}

struct TimezoneConverterDevToolView: View {
    @StateObject private var viewModel = TimezoneConverterViewModel()

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "Timezone Converter",
                description: "Compare times across global timezones and calculate offsets.",
                icon: "clock.badge.checkmark"
            )
            .padding()

            Form {
                Section("Base Time") {
                    DatePicker("Local Time", selection: $viewModel.baseDate)
                }

                Section("Target Timezones") {
                    ForEach($viewModel.targetTimezones, id: \.self) { $tzName in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(tzName).font(.subheadline.bold())
                                Text(viewModel.format(tzName)).font(.caption.monospaced())
                            }
                            Spacer()
                            Text(viewModel.offset(tzName))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { viewModel.targetTimezones.remove(atOffsets: $0) }

                    Button("Add Timezone") {
                         // Selection logic would go here
                         if let random = TimeZone.knownTimeZoneIdentifiers.randomElement() {
                             viewModel.targetTimezones.append(random)
                         }
                    }
                }
            }
        }
    }
}

class TimezoneConverterViewModel: ObservableObject {
    @Published var baseDate = Date()
    @Published var targetTimezones = ["UTC", "America/New_York", "Europe/London", "Asia/Tokyo"]

    func format(_ tzName: String) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: tzName)
        formatter.dateFormat = "HH:mm:ss (MMM d)"
        return formatter.string(from: baseDate)
    }

    func offset(_ tzName: String) -> String {
        guard let tz = TimeZone(identifier: tzName) else { return "" }
        let seconds = tz.secondsFromGMT(for: baseDate)
        let hours = seconds / 3600
        return String(format: "GMT%+d", hours)
    }
}
