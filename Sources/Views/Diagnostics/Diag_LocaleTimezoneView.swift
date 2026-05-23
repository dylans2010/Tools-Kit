import SwiftUI

struct Diag_LocaleTimezoneView: View {
    var body: some View {
        Form {
            Section("Locale") {
                LabeledContent("Identifier") { Text(Locale.current.identifier) }
                LabeledContent("Language") {
                    Text(Locale.current.localizedString(forLanguageCode: Locale.current.language.languageCode?.identifier ?? "") ?? "Unknown")
                }
                LabeledContent("Language Code") { Text(Locale.current.language.languageCode?.identifier ?? "N/A") }
                LabeledContent("Region") { Text(Locale.current.region?.identifier ?? "N/A") }
                LabeledContent("Script") { Text(Locale.current.language.script?.identifier ?? "N/A") }
                LabeledContent("Calendar") { Text(Locale.current.calendar.identifier.debugDescription) }
                LabeledContent("Measurement") {
                    Text(Locale.current.measurementSystem == .metric ? "Metric" : "Imperial")
                }
            }

            Section("Number Formatting") {
                LabeledContent("Decimal Separator") { Text(Locale.current.decimalSeparator ?? ".") }
                LabeledContent("Grouping Separator") { Text(Locale.current.groupingSeparator ?? ",") }
                LabeledContent("Currency Symbol") { Text(Locale.current.currencySymbol ?? "$") }
                LabeledContent("Currency Code") { Text(Locale.current.currency?.identifier ?? "N/A") }
                let nf = NumberFormatter()
                LabeledContent("Example Number") {
                    nf.numberStyle = .decimal
                    nf.locale = Locale.current
                    return Text(nf.string(from: 1234567.89 as NSNumber) ?? "1,234,567.89")
                }
            }

            Section("Timezone") {
                LabeledContent("Identifier") { Text(TimeZone.current.identifier) }
                LabeledContent("Abbreviation") { Text(TimeZone.current.abbreviation() ?? "N/A") }
                LabeledContent("Name") {
                    Text(TimeZone.current.localizedName(for: .standard, locale: .current) ?? "N/A")
                }
                LabeledContent("UTC Offset") {
                    let offset = TimeZone.current.secondsFromGMT()
                    let hours = offset / 3600
                    let minutes = abs(offset % 3600) / 60
                    Text(String(format: "UTC%+d:%02d", hours, minutes))
                        .monospacedDigit()
                }
                LabeledContent("DST") {
                    Text(TimeZone.current.isDaylightSavingTime() ? "Active" : "Inactive")
                        .foregroundStyle(TimeZone.current.isDaylightSavingTime() ? .orange : .green)
                }
                if TimeZone.current.isDaylightSavingTime() {
                    LabeledContent("DST Offset") {
                        Text(String(format: "%.0f min", TimeZone.current.daylightSavingTimeOffset() / 60))
                    }
                }
                if let nextTransition = TimeZone.current.nextDaylightSavingTimeTransition {
                    LabeledContent("Next Transition") {
                        Text(nextTransition, style: .date)
                    }
                }
            }

            Section("Date/Time Formatting") {
                let now = Date()
                LabeledContent("Short Date") {
                    Text(now.formatted(.dateTime.day().month().year()))
                }
                LabeledContent("Long Date") {
                    Text(now.formatted(.dateTime.weekday(.wide).day().month(.wide).year()))
                }
                LabeledContent("Time") {
                    Text(now.formatted(.dateTime.hour().minute().second()))
                }
                LabeledContent("24-Hour") {
                    let df = DateFormatter()
                    df.dateFormat = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: Locale.current)
                    let is24 = df.dateFormat?.contains("a") == false
                    Text(is24 ? "Yes" : "No")
                }
                LabeledContent("First Day of Week") {
                    let day = Calendar.current.firstWeekday
                    let symbols = Calendar.current.weekdaySymbols
                    Text(symbols[day - 1])
                }
            }

            Section("System Languages") {
                ForEach(Locale.preferredLanguages.prefix(5), id: \.self) { lang in
                    HStack {
                        Text(Locale.current.localizedString(forIdentifier: lang) ?? lang)
                        Spacer()
                        Text(lang)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Locale & Timezone")
        .navigationBarTitleDisplayMode(.inline)
    }
}
