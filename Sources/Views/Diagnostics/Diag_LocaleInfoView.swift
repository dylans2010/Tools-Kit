import SwiftUI

struct Diag_LocaleInfoView: View {
    private let locale = Locale.current

    var body: some View {
        Form {
            Section("Locale") {
                LabeledContent("Identifier") { Text(locale.identifier) }
                LabeledContent("Language Code") { Text(locale.language.languageCode?.identifier ?? "—") }
                LabeledContent("Region") { Text(locale.region?.identifier ?? "—") }
                LabeledContent("Script") { Text(locale.language.script?.identifier ?? "—") }
            }

            Section("Formatting") {
                LabeledContent("Currency") { Text(locale.currency?.identifier ?? "—") }
                LabeledContent("Currency Symbol") { Text(locale.currencySymbol ?? "—") }
                LabeledContent("Decimal Separator") { Text(locale.decimalSeparator ?? "—") }
                LabeledContent("Grouping Separator") { Text(locale.groupingSeparator ?? "—") }
            }

            Section("Calendar & Time") {
                LabeledContent("Calendar") { Text(locale.calendar.identifier.debugDescription) }
                LabeledContent("Time Zone") { Text(TimeZone.current.identifier) }
                LabeledContent("UTC Offset") {
                    let offset = TimeZone.current.secondsFromGMT() / 3600
                    Text("UTC\(offset >= 0 ? "+" : "")\(offset)")
                }
                LabeledContent("Uses 24h") {
                    let format = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: locale)
                    Text(format?.contains("a") == true ? "No" : "Yes")
                }
            }

            Section("Measurement") {
                LabeledContent("System") {
                    Text(locale.measurementSystem == .metric ? "Metric" : "US/Imperial")
                }
            }

            Section("Preferred Languages") {
                ForEach(Locale.preferredLanguages.prefix(5), id: \.self) { lang in
                    Text(lang)
                        .font(.subheadline)
                }
            }
        }
        .navigationTitle("Locale & Region")
        .navigationBarTitleDisplayMode(.inline)
    }
}
