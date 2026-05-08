import SwiftUI

struct SDKAutomationView: View {
    @StateObject private var engine = SDKAutomationEngine.shared
    @State private var showingAddSheet = false

    var body: some View {
        List {
            ForEach(engine.rules) { rule in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(rule.name).font(.headline)
                        Spacer()
                        Toggle("", isOn: binding(for: rule.id))
                            .labelsHidden()
                    }

                    Text(triggerSummary(rule.trigger))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack {
                        Label("\(rule.runCount) runs", systemImage: "play.circle")
                        if let lastRun = rule.lastRunAt {
                            Text("• Last: \(lastRun.formatted(.relative(presentation: .numeric)))")
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            .onDelete(perform: deleteRules)
        }
        .navigationTitle("Automation")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAddSheet = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddAutomationRuleView()
        }
    }

    private func binding(for id: UUID) -> Binding<Bool> {
        Binding(
            get: { engine.rules.first(where: { $0.id == id })?.isEnabled ?? false },
            set: { newValue in
                if let index = engine.rules.firstIndex(where: { $0.id == id }) {
                    engine.rules[index].isEnabled = newValue
                }
            }
        )
    }

    private func triggerSummary(_ trigger: AutomationTrigger) -> String {
        switch trigger {
        case .dataUpdated(let scope): return "When \(scope) Updated"
        case .connectorEvent(_, let event): return "On Connector Event: \(event)"
        case .timeBased(let interval): return "Every \(Int(interval)) Seconds"
        }
    }

    private func deleteRules(at offsets: IndexSet) {
        offsets.forEach { index in
            engine.remove(id: engine.rules[index].id)
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
                Section {
                    TextField("New Rule", text: $name)
                } header: {
                    Text("Rule Name")
                }

                Section {
                    Picker("Trigger Type", selection: $selectedTrigger) {
                        ForEach(TriggerType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }

                    if selectedTrigger == .data {
                        TextField("Scope (e.g. tasks)", text: $scope)
                    }
                } header: {
                    Text("Trigger")
                }

                Section {
                    Button("Save Rule") {
                        save()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .navigationTitle("New Rule")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func save() {
        let trigger: AutomationTrigger
        switch selectedTrigger {
        case .data: trigger = .dataUpdated(scope: scope)
        case .connector: trigger = .connectorEvent(connectorID: UUID(), eventName: "sync")
        case .timer: trigger = .timeBased(interval: 3600)
        }

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
