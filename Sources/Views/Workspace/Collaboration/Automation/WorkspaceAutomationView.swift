import SwiftUI

// MARK: - Automation List View

struct WorkspaceAutomationView: View {
    @StateObject private var engine = WorkspaceAutomationEngine.shared
    @State private var showingCreate = false
    @State private var selectedAutomation: WorkspaceAutomationEngine.Automation?

    var body: some View {
        List {
            Section {
                HStack {
                    Label("Total", systemImage: "bolt.fill")
                    Spacer()
                    Text("\(engine.automations.count)").foregroundStyle(.secondary)
                }
                HStack {
                    Label("Active", systemImage: "checkmark.circle.fill")
                    Spacer()
                    Text("\(engine.automations.filter { $0.isEnabled }.count)").foregroundStyle(.green)
                }
            } header: {
                Text("Overview")
            }

            Section("Automations") {
                if engine.automations.isEmpty {
                    Text("No automations yet. Tap + to create one.")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                } else {
                    ForEach(engine.automations) { (automation: WorkspaceAutomationEngine.Automation) in
                        AutomationRow(automation: automation, onTap: { selectedAutomation = automation })
                    }
                    .onDelete { offsets in
                        offsets.map { engine.automations[$0].id }.forEach { engine.deleteAutomation(id: $0) }
                    }
                }
            }

            Section("Recent Execution Log") {
                if engine.executionLog.isEmpty {
                    Text("No Executions Yet")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                } else {
                    ForEach(engine.executionLog.prefix(10), id: \.self) { entry in
                        Text(entry).font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Automations")
        .toolbar {
            Button(action: { showingCreate = true }) {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $showingCreate) {
            CreateAutomationView()
        }
        .sheet(item: $selectedAutomation) { automation in
            AutomationDetailView(automation: automation)
        }
    }
}

// MARK: - Row

struct AutomationRow: View {
    let automation: WorkspaceAutomationEngine.Automation
    let onTap: () -> Void
    @StateObject private var engine = WorkspaceAutomationEngine.shared

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(automation.name)
                        .font(.subheadline).bold()
                    Text("Trigger: \(automation.triggerType.rawValue)")
                        .font(.caption).foregroundStyle(.secondary)
                    if let last = automation.lastExecuted {
                        Text("Last Run: \(last, style: .relative)").font(.caption2).foregroundStyle(.tertiary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Toggle("", isOn: Binding(get: { automation.isEnabled }, set: { _ in engine.toggleAutomation(id: automation.id) }))
                        .labelsHidden()
                    Text("\(automation.executionCount) Runs").font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Create Automation

struct CreateAutomationView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var engine = WorkspaceAutomationEngine.shared

    @State private var name = ""
    @State private var trigger = WorkspaceAutomationEngine.TriggerType.taskOverdue
    @State private var conditionField = ""
    @State private var conditionValue = ""
    @State private var conditionOp = WorkspaceAutomationEngine.ConditionOperator.always
    @State private var actionType = WorkspaceAutomationEngine.ActionType.logActivity
    @State private var actionParam = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Automation Name", text: $name)
                }

                Section("Trigger") {
                    Picker("Event", selection: $trigger) {
                        ForEach(WorkspaceAutomationEngine.TriggerType.allCases, id: \.self) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                }

                Section("Condition (Optional)") {
                    Picker("Operator", selection: $conditionOp) {
                        ForEach(WorkspaceAutomationEngine.ConditionOperator.allCases, id: \.self) { op in
                            Text(op.rawValue).tag(op)
                        }
                    }
                    if conditionOp != .always {
                        TextField("Field (e.g. taskTitle)", text: $conditionField)
                        TextField("Value", text: $conditionValue)
                    }
                }

                Section("Action") {
                    Picker("Action", selection: $actionType) {
                        ForEach(WorkspaceAutomationEngine.ActionType.allCases, id: \.self) { a in
                            Text(a.rawValue).tag(a)
                        }
                    }
                    TextField("Parameter (Optional)", text: $actionParam)
                }
            }
            .navigationTitle("New Automation")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let conditions: [WorkspaceAutomationEngine.AutomationCondition] = conditionOp != .always ? [
                            WorkspaceAutomationEngine.AutomationCondition(id: UUID(), field: conditionField, conditionOperator: conditionOp, value: conditionValue)
                        ] : []
                        let paramKey: String
                        switch actionType {
                        case .sendNotification: paramKey = "title"
                        case .assignMember: paramKey = "member"
                        case .updateStatus: paramKey = "status"
                        default: paramKey = "message"
                        }
                        let actions = [WorkspaceAutomationEngine.AutomationAction(id: UUID(), actionType: actionType, parameters: [paramKey: actionParam])]
                        engine.createAutomation(name: name, trigger: trigger, conditions: conditions, actions: actions)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// MARK: - Automation Detail

struct AutomationDetailView: View {
    let automation: WorkspaceAutomationEngine.Automation
    @StateObject private var engine = WorkspaceAutomationEngine.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Trigger") {
                    Label(automation.triggerType.rawValue, systemImage: "bolt.fill")
                }
                Section("Conditions") {
                    if automation.conditions.isEmpty {
                        Text("No Conditions (Always Runs)").foregroundStyle(.secondary)
                    } else {
                        ForEach(automation.conditions) { c in
                            Text("\(c.field) \(c.conditionOperator.rawValue) \(c.value)")
                        }
                    }
                }
                Section("Actions") {
                    if automation.actions.isEmpty {
                        Text("No Actions Defined").foregroundStyle(.secondary)
                    } else {
                        ForEach(automation.actions) { a in
                            Label(a.actionType.rawValue, systemImage: "play.fill")
                        }
                    }
                }
                Section("Stats") {
                    LabeledContent("Executions", value: "\(automation.executionCount)")
                    if let last = automation.lastExecuted {
                        LabeledContent("Last Run", value: last.formatted(date: .abbreviated, time: .shortened))
                    }
                    LabeledContent("Created", value: automation.createdAt.formatted(date: .abbreviated, time: .omitted))
                }

                Section {
                    Button("Test Fire Now") {
                        engine.fire(trigger: automation.triggerType, context: ["taskTitle": "Test Task"])
                    }
                    .foregroundStyle(.blue)
                }
            }
            .navigationTitle(automation.name)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(automation.isEnabled ? "Disable" : "Enable") {
                        engine.toggleAutomation(id: automation.id)
                        dismiss()
                    }
                    .foregroundStyle(automation.isEnabled ? .red : .green)
                }
            }
        }
    }
}
