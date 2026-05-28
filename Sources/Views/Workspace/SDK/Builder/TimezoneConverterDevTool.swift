import SwiftUI

struct TimezoneConverterDevTool: DevTool {
    let id = "timezone-converter"
    let name = "Timezone Converter"
    let category = DevToolCategory.data
    let icon = "clock.badge.checkmark"
    let description = "Convert times between timezones with world clock"

    func render() -> some View {
        TimezoneConverterDevToolView()
    }
}

struct TimezoneConverterDevToolView: View {
    @StateObject private var viewModel = TimezoneConverterViewModel()
    @State private var searchText = ""

    var body: some View {
        Form {
            Section(header: Text("Base Time")) {
                DatePicker("Date & Time", selection: $viewModel.baseDate)
                HStack {
                    Button("Now") { viewModel.baseDate = Date() }
                        .buttonStyle(.bordered).controlSize(.small)
                    Spacer()
                    Text("Unix: \(Int(viewModel.baseDate.timeIntervalSince1970))")
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                }
            }

            Section(header: Text("World Clock")) {
                ForEach(viewModel.targetTimezones, id: \.self) { tzName in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.cityName(tzName))
                                .font(.subheadline.bold())
                            Text(tzName)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(viewModel.formatTime(tzName))
                                .font(.system(.subheadline, design: .monospaced).bold())
                            HStack(spacing: 4) {
                                Text(viewModel.formatDate(tzName))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(viewModel.offset(tzName))
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                    .padding(.horizontal, 4)
                                    .background(Color.secondary.opacity(0.1), in: Capsule())
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
                .onDelete { viewModel.targetTimezones.remove(atOffsets: $0) }
            }

            Section(header: Text("Add Timezone")) {
                TextField("Search timezones...", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                if !searchText.isEmpty {
                    ForEach(viewModel.filteredTimezones(searchText), id: \.self) { tz in
                        Button {
                            if !viewModel.targetTimezones.contains(tz) {
                                viewModel.targetTimezones.append(tz)
                            }
                            searchText = ""
                        } label: {
                            HStack {
                                Text(viewModel.cityName(tz))
                                    .font(.caption)
                                Spacer()
                                Text(viewModel.offset(tz))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Section(header: Text("Quick Add")) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(viewModel.popularTimezones, id: \.self) { tz in
                            Button(viewModel.cityName(tz)) {
                                if !viewModel.targetTimezones.contains(tz) {
                                    viewModel.targetTimezones.append(tz)
                                }
                            }
                            .buttonStyle(.bordered).controlSize(.mini)
                            .disabled(viewModel.targetTimezones.contains(tz))
                        }
                    }
                }
            }

            Section(header: Text("Time Differences")) {
                ForEach(viewModel.targetTimezones, id: \.self) { tzName in
                    HStack {
                        Text(viewModel.cityName(tzName)).font(.caption)
                        Spacer()
                        Text(viewModel.timeDifference(tzName))
                            .font(.caption.monospaced())
                            .foregroundStyle(viewModel.timeDiffColor(tzName))
                    }
                }
            }
        }
    }
}

class TimezoneConverterViewModel: ObservableObject {
    @Published var baseDate = Date()
    @Published var targetTimezones = ["UTC", "America/New_York", "Europe/London", "Asia/Tokyo", "Australia/Sydney"]

    let popularTimezones = ["America/Chicago", "America/Los_Angeles", "Europe/Berlin", "Europe/Paris", "Asia/Shanghai", "Asia/Kolkata", "Asia/Dubai", "Pacific/Auckland"]

    func cityName(_ tz: String) -> String {
        tz.components(separatedBy: "/").last?.replacingOccurrences(of: "_", with: " ") ?? tz
    }

    func formatTime(_ tzName: String) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: tzName)
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: baseDate)
    }

    func formatDate(_ tzName: String) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: tzName)
        formatter.dateFormat = "MMM d"
        return formatter.string(from: baseDate)
    }

    func offset(_ tzName: String) -> String {
        guard let tz = TimeZone(identifier: tzName) else { return "" }
        let seconds = tz.secondsFromGMT(for: baseDate)
        let hours = seconds / 3600
        let minutes = abs(seconds % 3600) / 60
        if minutes == 0 {
            return String(format: "UTC%+d", hours)
        }
        return String(format: "UTC%+d:%02d", hours, minutes)
    }

    func timeDifference(_ tzName: String) -> String {
        guard let tz = TimeZone(identifier: tzName) else { return "" }
        let localOffset = TimeZone.current.secondsFromGMT(for: baseDate)
        let targetOffset = tz.secondsFromGMT(for: baseDate)
        let diff = (targetOffset - localOffset) / 3600
        if diff == 0 { return "Same time" }
        return diff > 0 ? "+\(diff)h" : "\(diff)h"
    }

    func timeDiffColor(_ tzName: String) -> Color {
        guard let tz = TimeZone(identifier: tzName) else { return .secondary }
        let localOffset = TimeZone.current.secondsFromGMT(for: baseDate)
        let targetOffset = tz.secondsFromGMT(for: baseDate)
        let diff = targetOffset - localOffset
        if diff == 0 { return .secondary }
        return diff > 0 ? .green : .orange
    }

    func filteredTimezones(_ query: String) -> [String] {
        TimeZone.knownTimeZoneIdentifiers
            .filter { $0.localizedCaseInsensitiveContains(query) }
            .filter { !targetTimezones.contains($0) }
            .prefix(8)
            .map { $0 }
    }
}

#Preview {
    TimezoneConverterDevToolView()
}
