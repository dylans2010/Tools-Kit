import SwiftUI

struct LogAlertRulesView: View {
    @ObservedObject var logService = DeveloperLogService.shared
    @State private var showingAdd = false
    @State private var newName = ""
    @State private var selectedSeverity: LogSeverity = .error
    @State private var selectedCategory: LogCategory = .apiCall
    @State private var threshold = 10
    @State private var timeWindow: TimeInterval = 60

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
        .sheet(isPresented: $showingAdd) {
            addRuleSheet
        }
    }

    private var addRuleSheet: some View {
        NavigationStack {
            Form {
                Section("Rule Name") {
                    TextField("Name", text: $newName)
                }
                Section("Conditions") {
                    Picker("Severity", selection: $selectedSeverity) {
                        ForEach(LogSeverity.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(LogCategory.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    Stepper("Threshold: \(threshold) events", value: $threshold, in: 1...100)
                    Picker("Time Window", selection: $timeWindow) {
                        Text("1 Minute").tag(TimeInterval(60))
                        Text("5 Minutes").tag(TimeInterval(300))
                        Text("15 Minutes").tag(TimeInterval(900))
                    }
                }
            }
            .navigationTitle("New Alert Rule")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAdd = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        saveRule()
                    }
                    .disabled(newName.isEmpty)
                }
            }
        }
    }

    private func saveRule() {
        let rule = LogAlertRule(name: newName, severity: selectedSeverity, category: selectedCategory, threshold: threshold, timeWindow: timeWindow)
        Task {
            try? await logService.saveAlertRule(rule)
            await MainActor.run {
                showingAdd = false
                newName = ""
            }
        }
    }

    private func deleteRule(at offsets: IndexSet) {
        for index in offsets {
            let rule = logService.alertRules[index]
            Task { try? await logService.deleteAlertRule(id: rule.id) }
        }
    }
}
