import SwiftUI

struct CronParserView: View {
    @State private var cronExpression = "* * * * *"
    @State private var explanation = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Cron Expression").font(.headline)
                    TextField("e.g. 0 12 * * *", text: $cronExpression)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.subheadline, design: .monospaced))
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
                        .onChange(of: cronExpression) { _ in parse() }
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Explanation").font(.headline)

                    Text(explanation.isEmpty ? "Type a valid cron expression" : explanation)
                        .font(.subheadline)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.accentColor.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Cheat Sheet").font(.headline)
                    cheatSheetRow(label: "*", value: "Any value")
                    cheatSheetRow(label: ",", value: "Value list separator")
                    cheatSheetRow(label: "-", value: "Range of values")
                    cheatSheetRow(label: "/", value: "Step values")
                }
            }
            .padding()
        }
        .navigationTitle("Cron Parser")
        .background(Color(uiColor: .systemGroupedBackground))
        .onAppear(perform: parse)
    }

    private func cheatSheetRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.system(.caption, design: .monospaced)).bold()
                .frame(width: 40, alignment: .leading)
            Text(value).font(.caption).foregroundStyle(.secondary)
        }
    }

    private func parse() {
        let parts = cronExpression.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard parts.count == 5 else {
            explanation = "Invalid expression: must have 5 parts (min, hour, dom, mon, dow)"
            return
        }

        explanation = "Runs at the specified interval:\n"
        explanation += "• Minutes: \(parts[0])\n"
        explanation += "• Hours: \(parts[1])\n"
        explanation += "• Day of Month: \(parts[2])\n"
        explanation += "• Month: \(parts[3])\n"
        explanation += "• Day of Week: \(parts[4])"
    }
}
