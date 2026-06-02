import SwiftUI

struct LocaleInspectorDevTool: DevTool {
    let id = "locale-inspector"
    let name = "Locale Inspector"
    let category: DevToolCategory = .diagnostics
    let icon = "globe"
    let description = "Inspect locale settings and formatting rules"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Enter locale ID (e.g. en_US)") { input in let locale = Locale(identifier: input.isEmpty ? Locale.current.identifier : input); return "Identifier: \(locale.identifier)\nLanguage: \(locale.language.languageCode?.identifier ?? "Unknown")\nRegion: \(locale.region?.identifier ?? "Unknown")\nCalendar: \(locale.calendar.identifier)\nCurrency: \(locale.currency?.identifier ?? "N/A")" } }
}
