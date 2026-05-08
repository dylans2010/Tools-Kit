import SwiftUI

struct SDKAutomationView: View {
    @StateObject private var engine = SDKAutomationEngine.shared
    @State private var showingAddSheet = false

    var body: some View {
        List {
            Section {
                if engine.rules.isEmpty {
                    ContentUnavailableView("No Automation Rules", systemImage: "bolt.slash.fill", description: Text("Create rules to automate SDK actions based on system events."))
                        .padding(.vertical, 20)
                } else {
                    ForEach(engine.rules) { rule in
                        automationRuleCard(rule)
                    }
                    .onDelete(perform: deleteRules)
                }
            } header: {
                SDKSectionHeader("Active Rules", subtitle: "Managed system event triggers", systemImage: "bolt.fill")
            }
        }
        .navigationTitle("Automation")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAddSheet = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddAutomationRuleView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private func automationRuleCard(_ rule: SDKAutomationRule) -> some View {
        SDKModernCard(padding: 12, content: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(rule.name).font(.subheadline.bold())
                        Text(triggerSummary(rule.trigger))
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: binding(for: rule.id))
                        .labelsHidden()
                        .tint(.primary)
                }

                Divider().opacity(0.3)

                HStack {
                    Label("\(rule.runCount) Executions", systemImage: "play.circle.fill")
                    Spacer()
                    if let lastRun = rule.lastRunAt {
                        Text("Last: \(lastRun.formatted(.relative(presentation: .numeric)))")
                    } else {
                        Text("Never triggered")
                    }
                }
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
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
