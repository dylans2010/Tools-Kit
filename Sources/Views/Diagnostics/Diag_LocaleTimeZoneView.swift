import SwiftUI

struct Diag_LocaleTimeZoneView: View {
    @State private var localeInfo: [(String, String)] = []
    @State private var timeZoneInfo: [(String, String)] = []

    var body: some View {
        Form {
            Section("Locale & Time Zone") {
                VStack(spacing: 8) {
                    Image(systemName: "globe")
                        .font(.system(size: 44))
                        .foregroundStyle(.blue)
                    Text(Locale.current.language.languageCode?.identifier.uppercased() ?? "??")
                        .font(.title.bold())
                    Text(TimeZone.current.identifier)
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Locale Details") {
                ForEach(localeInfo, id: \.0) { info in
                    LabeledContent(info.0) { Text(info.1).font(.caption) }
                }
            }

            Section("Time Zone Details") {
                ForEach(timeZoneInfo, id: \.0) { info in
                    LabeledContent(info.0) { Text(info.1).font(.caption) }
                }
            }

            Section { Button { loadInfo() } label: { HStack { Image(systemName: "arrow.clockwise"); Text("Refresh") } } }
        }
        .navigationTitle("Locale & Time Zone")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadInfo() }
    }

    private func loadInfo() {
        let locale = Locale.current
        var lInfo: [(String, String)] = []

        lInfo.append(("Identifier", locale.identifier))
        lInfo.append(("Language", locale.language.languageCode?.identifier ?? "Unknown"))
        lInfo.append(("Region", locale.region?.identifier ?? "Unknown"))
        lInfo.append(("Script", locale.language.script?.identifier ?? "N/A"))
        lInfo.append(("Currency", locale.currency?.identifier ?? "Unknown"))
        lInfo.append(("Currency Symbol", locale.currencySymbol ?? "?"))
        lInfo.append(("Decimal Separator", locale.decimalSeparator ?? "."))
        lInfo.append(("Grouping Separator", locale.groupingSeparator ?? ","))
        lInfo.append(("Measurement System", locale.measurementSystem == .metric ? "Metric" : "US"))
        lInfo.append(("Calendar", locale.calendar.identifier.debugDescription))

        let preferred = Locale.preferredLanguages
        lInfo.append(("Preferred Languages", preferred.prefix(5).joined(separator: ", ")))

        localeInfo = lInfo

        let tz = TimeZone.current
        var tzInfo: [(String, String)] = []
        tzInfo.append(("Identifier", tz.identifier))
        tzInfo.append(("Abbreviation", tz.abbreviation() ?? "N/A"))
        tzInfo.append(("GMT Offset", "\(tz.secondsFromGMT() / 3600)h \((tz.secondsFromGMT() % 3600) / 60)m"))
        tzInfo.append(("DST Active", tz.isDaylightSavingTime() ? "Yes" : "No"))
        if tz.isDaylightSavingTime() {
            tzInfo.append(("DST Offset", "\(Int(tz.daylightSavingTimeOffset() / 3600))h"))
            if let nextTransition = tz.nextDaylightSavingTimeTransition {
                tzInfo.append(("Next DST Change", DateFormatter.localizedString(from: nextTransition, dateStyle: .medium, timeStyle: .short)))
            }
        }
        tzInfo.append(("Local Time", DateFormatter.localizedString(from: Date(), dateStyle: .full, timeStyle: .long)))

        timeZoneInfo = tzInfo
    }
}
