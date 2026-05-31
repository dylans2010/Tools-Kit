import SwiftUI

struct LogAlertRulesView: View {
    @ObservedObject var logService = DeveloperLogService.shared
    @State private var showingAdd = false
    @State private var newName = ""
    @State private var selectedCategory: LogCategory = .application
    @State private var selectedSeverity: LogSeverity = .error
    @State private var threshold = "10"
    @State private var window = "60"

    var body: some View {
        List {
            Section("Streaming Alerts") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "bell.badge.fill").foregroundStyle(.orange)
                        Text("Active Monitoring").font(.subheadline.bold())
                    }
                    Text("Receive push notifications or webhook triggers when log patterns exceed your defined thresholds.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Managed Rules") {
                if logService.alertRules.isEmpty {
                    EmptyStateView(icon: "bell.slash", title: "No Alerts", message: "Configure an alert rule to be proactively notified of system failures or anomalous behavior.")
                } else {
                    ForEach(logService.alertRules) { rule in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(rule.name).font(.subheadline.bold())
                                Spacer()
                                Text("ACTIVE").font(.system(size: 8, weight: .black)).foregroundStyle(.green)
                            }

                            HStack(spacing: 8) {
                                Text(rule.category.rawValue.uppercased()).font(.system(size: 8, weight: .black)).padding(.horizontal, 6).padding(.vertical, 2).background(Color.primary.opacity(0.05), in: Capsule())
                                Text(rule.severity.rawValue.uppercased()).font(.system(size: 8, weight: .black)).padding(.horizontal, 6).padding(.vertical, 2).background(Color.red.opacity(0.1)).foregroundStyle(.red).clipShape(Capsule())
                                Spacer()
                                Text(">\(rule.threshold) in \(Int(rule.timeWindow))s").font(.system(size: 9, design: .monospaced)).foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: deleteRule)
                }
            }

            Section {
                Button { showingAdd = true } label: {
                    Label("Add Alert Rule", systemImage: "plus.circle.fill").font(.subheadline.bold())
                }
            }
        }
        .navigationTitle("Log Alerts")
        .sheet(isPresented: $showingAdd) { addRuleSheet }
    }

    private var addRuleSheet: some View {
        NavigationStack {
            Form {
                Section("Metadata") {
                    TextField("Rule Name", text: $newName, prompt: Text("e.g. Auth Failures"))
                }

                Section("Filter Criteria") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(LogCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    Picker("Severity", selection: $selectedSeverity) {
                        ForEach(LogSeverity.allCases, id: \.self) { sev in
                            Text(sev.rawValue).tag(sev)
                        }
                    }
                }

                Section("Thresholds") {
                    HStack {
                        Text("Count")
                        Spacer()
                        TextField("10", text: $threshold).keyboardType(.numberPad).multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Window (sec)")
                        Spacer()
                        TextField("60", text: $window).keyboardType(.numberPad).multilineTextAlignment(.trailing)
                    }
                }
            }
            .navigationTitle("New Alert Rule")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAdd = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createRule()
                    }
                    .disabled(newName.isEmpty)
                }
            }
        }
    }

    private func createRule() {
        let rule = LogAlertRule(
            name: newName,
            category: selectedCategory,
            severity: selectedSeverity,
            threshold: Int(threshold) ?? 10,
            timeWindow: TimeInterval(window) ?? 60,
            notificationMethod: "Push"
        )
        Task {
            try? await logService.createAlertRule(rule)
            await MainActor.run { showingAdd = false; newName = "" }
        }
    }

    private func deleteRule(at offsets: IndexSet) {
        for index in offsets {
            let rule = logService.alertRules[index]
            Task { try? await logService.deleteAlertRule(id: rule.id) }
        }
    }
}
