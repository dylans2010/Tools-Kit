import SwiftUI

struct PluralizationRulesDevTool: DevTool {
    let id = "plural-rules"
    let name = "Pluralization Rules"
    let category: DevToolCategory = .data
    let icon = "plus.minus"
    let description = "Cheat sheet for ICU plural rules in iOS"

    func render() -> some View {
        List {
            Section("Plural Categories") {
                Text("zero: 0")
                Text("one: 1 (in many languages)")
                Text("two: 2")
                Text("few: specific small numbers")
                Text("many: specific large numbers")
                Text("other: fallback category")
            }
            Section("Example .stringsdict") {
                Text("<key>numberOfSongs</key>\n<dict>\n  <key>NSStringLocalizedFormatKey</key>\n  <string>%#@songs@</string>\n  <key>songs</key>\n  <dict>\n    <key>NSStringFormatSpecTypeKey</key>\n    <string>NSStringPluralRuleType</string>\n    <key>NSStringFormatValueTypeKey</key>\n    <string>d</string>\n    <key>one</key>\n    <string>One song</string>\n    <key>other</key>\n    <string>%d songs</string>\n  </dict>\n</dict>")
                    .font(.system(.caption, design: .monospaced))
            }
        }
    }
}
