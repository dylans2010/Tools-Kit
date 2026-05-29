import SwiftUI

struct LogAlertRulesView: View {
    @ObservedObject var logService = DeveloperLogService.shared
    @State private var showingAdd = false
    @State private var newName = ""

    var body: some View {
        List {
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
