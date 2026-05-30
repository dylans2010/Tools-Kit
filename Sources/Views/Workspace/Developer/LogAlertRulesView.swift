import SwiftUI

struct LogAlertRulesView: View {
    @ObservedObject var logService = DeveloperLogService.shared
    @State private var showingAdd = false
    @State private var newName = ""
    @State private var selectedCategory: LogCategory = .system
    @State private var selectedSeverity: LogSeverity = .error
    @State private var threshold = "10"

    var body: some View {
        List {
            Section("Add New Rule") {
                TextField("Rule Name", text: $newName)
                Picker("Category", selection: $selectedCategory) {
                    ForEach(LogCategory.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                Picker("Min Severity", selection: $selectedSeverity) {
                    ForEach(LogSeverity.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                TextField("Threshold (occurrences)", text: $threshold)
                    .keyboardType(.numberPad)

                Button("Create Rule") {
                    let rule = LogAlertRule(name: newName, category: selectedCategory, severity: selectedSeverity, threshold: Int(threshold) ?? 10, timeWindow: 300, notificationMethod: "Internal")
                    Task {
                        try? await logService.saveAlertRule(rule)
                        await MainActor.run {
                            newName = ""
                            threshold = "10"
                        }
                    }
                }
                .disabled(newName.isEmpty)
            }

            Section("Active Alert Rules") {
                if logService.alertRules.isEmpty {
                    Text("No alert rules configured. Create rules to be notified of critical log events.").foregroundStyle(.secondary)
                } else {
                    ForEach(logService.alertRules) { rule in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(rule.name).font(.headline)
                            Text("\(rule.category.rawValue) • \(rule.severity.rawValue) • >\(rule.threshold) in \(Int(rule.timeWindow))s").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .onDelete(perform: deleteRule)
                }
            }
        }
        .navigationTitle("Log Alerts")
        .toolbar {
            Button { showingAdd = true } label: { Image(systemName: "plus") }
        }
    }

    private func deleteRule(at offsets: IndexSet) {
        for index in offsets {
            let rule = logService.alertRules[index]
            Task { try? await logService.deleteAlertRule(id: rule.id) }
        }
    }
}
