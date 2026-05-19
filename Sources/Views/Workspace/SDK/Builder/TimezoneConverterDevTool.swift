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
        List {
            Section("Current Origin") {
                DatePicker("Local Time", selection: $viewModel.baseDate)
                LabeledContent("Identifier", value: TimeZone.current.identifier)
                    .font(.caption)
            }

            Section("Global Clock (\(viewModel.targetTimezones.count))") {
                ForEach(viewModel.targetTimezones, id: \.self) { tzName in
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(tzName.split(separator: "/").last?.replacingOccurrences(of: "_", with: " ") ?? tzName)
                                .font(.subheadline.bold())
                            Text(tzName).font(.system(size: 8, design: .monospaced)).foregroundStyle(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text(viewModel.format(tzName))
                                .font(.system(.subheadline, design: .monospaced))
                                .foregroundStyle(.blue)
                            Text(viewModel.offset(tzName))
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(0.1), in: Capsule())
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { viewModel.targetTimezones.remove(atOffsets: $0) }

                Menu {
                    ForEach(["Europe/Paris", "America/Los_Angeles", "Asia/Dubai", "Australia/Sydney", "Pacific/Auckland"], id: \.self) { id in
                        Button(id) { viewModel.targetTimezones.append(id) }
                    }
                } label: {
                    Label("Quick Add City", systemImage: "plus.circle")
                }
            }
        }
        .navigationTitle("Timezones")
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

#Preview {
    TimezoneConverterDevToolView()
}
