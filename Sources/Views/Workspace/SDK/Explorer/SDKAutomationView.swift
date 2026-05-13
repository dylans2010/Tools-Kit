

import SwiftUI

struct SDKAutomationView: View {
    @StateObject private var engine = SDKAutomationEngine.shared
    @State private var showingAddSheet = false

    var body: some View {
        List {
            Section("Active Triggers") {
                if engine.rules.isEmpty {
                    ContentUnavailableView(
                        "No Automation Rules",
                        systemImage: "bolt.slash",
                        description: Text("Create rules to automate SDK actions based on system events.")
                    )
                } else {
                    ForEach(engine.rules) { rule in
                        AutomationRuleRow(rule: rule, engine: engine)
                    }
                    .onDelete(perform: deleteRules)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Automation")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Label("Add Rule", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddAutomationRuleView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
        }
    }

    private func deleteRules(at offsets: IndexSet) {
        offsets.forEach { index in
            engine.remove(id: engine.rules[index].id)
        }
    }
}

// MARK: - Private Subviews

private struct AutomationRuleRow: View {
    let rule: SDKAutomationRule
    @ObservedObject var engine: SDKAutomationEngine

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(rule.name).font(.headline)
                    Text(triggerSummary(rule.trigger))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { engine.rules.first(where: { $0.id == rule.id })?.isEnabled ?? false },
                    set: { newValue in
                        if let index = engine.rules.firstIndex(where: { $0.id == rule.id }) {
                            engine.rules[index].isEnabled = newValue
                        }
                    }
                ))
                .labelsHidden()
            }

            HStack {
                Label("\(rule.runCount) runs", systemImage: "play.circle")
                Spacer()
                if let lastRun = rule.lastRunAt {
                    Text("Last: \(lastRun.formatted(.relative(presentation: .numeric)))")
                } else {
                    Text("Never triggered")
                }
            }
            .font(.caption2.bold())
            .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    private func triggerSummary(_ trigger: AutomationTrigger) -> String {
        switch trigger {
        case .dataUpdated(let scope): return "When \(scope) updated"
        case .connectorEvent(_, let event): return "On connector event: \(event)"
        case .timeBased(let interval): return "Every \(Int(interval)) seconds"
        }
    }
}

struct AddAutomationRuleView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var selectedTrigger: TriggerType = .data
    @State private var scope = "tasks"

    enum TriggerType: String, CaseIterable {
        case data = "Data Updated", connector = "Connector Event", timer = "Timer"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Rule Identity") {
                    TextField("Name", text: $name)
                }

                Section("Trigger") {
                    Picker("Type", selection: $selectedTrigger) {
                        ForEach(TriggerType.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }

                    if selectedTrigger == .data {
                        TextField("Scope (e.g. tasks)", text: $scope)
                            .textInputAutocapitalization(.never)
                    }
                }

                Section {
                    Button("Save Automation") {
                        save()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("New Rule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func save() {
        let trigger: AutomationTrigger = {
            switch selectedTrigger {
            case .data: return .dataUpdated(scope: scope)
            case .connector: return .connectorEvent(connectorID: UUID(), eventName: "sync")
            case .timer: return .timeBased(interval: 3600)
            }
        }()

        let rule = SDKAutomationRule(
            id: UUID(),
            name: name,
            trigger: trigger,
            condition: nil,
            action: .sendNotification(title: "Automation Run", body: "Rule \(name) Triggered"),
            isEnabled: true,
            lastRunAt: nil,
            runCount: 0
        )
        SDKAutomationEngine.shared.add(rule)
    }
}
