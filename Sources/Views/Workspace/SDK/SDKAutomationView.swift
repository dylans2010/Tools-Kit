import SwiftUI

struct SDKAutomationView: View {
    @StateObject private var engine = SDKAutomationEngine.shared
    @State private var showingAddRule = false

    var body: some View {
        List {
            ForEach(engine.rules) { rule in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(rule.name).font(.headline)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { rule.isEnabled },
                            set: { val in
                                if let idx = engine.rules.firstIndex(where: { $0.id == rule.id }) {
                                    engine.rules[idx].isEnabled = val
                                }
                            }
                        )).labelsHidden()
                    }

                    Text(triggerSummary(rule.trigger))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack {
                        Label("\(rule.runCount)", systemImage: "play.circle")
                        Spacer()
                        if let lastRun = rule.lastRunAt {
                            Text("Last: \(lastRun, style: .time)")
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
                .swipeActions {
                    Button(role: .destructive) {
                        engine.remove(id: rule.id)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("Automation")
        .toolbar {
            Button(action: { showingAddRule = true }) {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $showingAddRule) {
            AddAutomationRuleView()
        }
    }

    private func triggerSummary(_ trigger: AutomationTrigger) -> String {
        switch trigger {
        case .dataUpdated(let scope): return "Trigger: Data updated in \(scope)"
        case .connectorEvent(let id, let event): return "Trigger: \(event) from connector \(id.uuidString.prefix(8))"
        case .timeBased(let interval): return "Trigger: Every \(Int(interval)) seconds"
        }
    }
}

struct AddAutomationRuleView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var selectedTriggerType = 0
    @State private var selectedActionType = 0

    var body: some View {
        NavigationStack {
            Form {
                Section("Rule Name") {
                    TextField("My Automation", text: $name)
                }

                Section("Trigger") {
                    Picker("Type", selection: $selectedTriggerType) {
                        Text("Data Updated").tag(0)
                        Text("Connector Event").tag(1)
                        Text("Time Based").tag(2)
                    }
                }

                Section("Action") {
                    Picker("Action", selection: $selectedActionType) {
                        Text("Run Tool").tag(0)
                        Text("Sync Connector").tag(1)
                        Text("Notification").tag(2)
                    }
                }

                Section {
                    Button("Save Rule") {
                        let rule = SDKAutomationRule(
                            name: name,
                            trigger: .dataUpdated(scope: .notes),
                            action: .sendNotification(title: "Automation", body: "Triggered!")
                        )
                        SDKAutomationEngine.shared.add(rule)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .navigationTitle("Add Rule")
            .toolbar {
                Button("Cancel") { dismiss() }
            }
        }
    }
}
