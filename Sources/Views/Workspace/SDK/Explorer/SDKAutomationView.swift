

import SwiftUI

struct SDKAutomationView: View {
    @StateObject private var engine = SDKAutomationEngine.shared
    @State private var showingAddSheet = false
    @State private var searchText = ""
    @State private var filterEnabled: AutomationFilter = .all
    @State private var showingRunHistory = false
    @State private var showingBulkActions = false
    @State private var showingExport = false
    @State private var runHistory: [AutomationRunEntry] = []
    @State private var showingStats = false

    private var filteredRules: [SDKAutomationRule] {
        var rules = engine.rules
        if !searchText.isEmpty {
            rules = rules.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        switch filterEnabled {
        case .all: break
        case .enabled: rules = rules.filter(\.isEnabled)
        case .disabled: rules = rules.filter { !$0.isEnabled }
        }
        return rules
    }

    var body: some View {
        List {
            automationStatsSection
            filterSection
            activeTriggersSection
            recentRunsSection
            bulkActionsSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Automation")
        .searchable(text: $searchText, prompt: "Search rules")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button { showingAddSheet = true } label: { Label("Add Rule", systemImage: "plus") }
                    Button { showingRunHistory = true } label: { Label("Run History", systemImage: "clock") }
                    Button { showingExport = true } label: { Label("Export Rules", systemImage: "square.and.arrow.up") }
                    Divider()
                    Button { enableAllRules() } label: { Label("Enable All", systemImage: "bolt.fill") }
                    Button { disableAllRules() } label: { Label("Disable All", systemImage: "bolt.slash") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddAutomationRuleView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
        }
        .sheet(isPresented: $showingRunHistory) {
            NavigationStack { runHistorySheet }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingExport) {
            NavigationStack { exportRulesSheet }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Stats Section

    private var automationStatsSection: some View {
        Section("Overview") {
            HStack(spacing: 16) {
                VStack(spacing: 2) {
                    Text("\(engine.rules.count)").font(.title3.bold()).foregroundStyle(.blue)
                    Text("Rules").font(.caption2).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                VStack(spacing: 2) {
                    Text("\(engine.rules.filter(\.isEnabled).count)").font(.title3.bold()).foregroundStyle(.green)
                    Text("Enabled").font(.caption2).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                VStack(spacing: 2) {
                    Text("\(engine.rules.reduce(0) { $0 + $1.runCount })").font(.title3.bold()).foregroundStyle(.orange)
                    Text("Total Runs").font(.caption2).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Filter Section

    private var filterSection: some View {
        Section {
            Picker("Filter", selection: $filterEnabled) {
                Text("All").tag(AutomationFilter.all)
                Text("Enabled").tag(AutomationFilter.enabled)
                Text("Disabled").tag(AutomationFilter.disabled)
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Active Triggers Section

    private var activeTriggersSection: some View {
        Section("Automation Rules") {
            if filteredRules.isEmpty {
                ContentUnavailableView(
                    "No Automation Rules",
                    systemImage: "bolt.slash",
                    description: Text("Create rules to automate SDK actions based on system events.")
                )
            } else {
                ForEach(filteredRules) { rule in
                    AutomationRuleRow(rule: rule, engine: engine) {
                        runHistory.insert(AutomationRunEntry(ruleName: rule.name, success: true, timestamp: Date()), at: 0)
                    }
                }
                .onDelete(perform: deleteRules)
            }
        }
    }

    // MARK: - Recent Runs

    private var recentRunsSection: some View {
        Section("Recent Runs") {
            if runHistory.isEmpty {
                Text("No runs recorded").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(runHistory.prefix(5)) { entry in
                    HStack {
                        Image(systemName: entry.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(entry.success ? .green : .red)
                        Text(entry.ruleName).font(.subheadline)
                        Spacer()
                        Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                            .font(.caption2).foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }

    // MARK: - Bulk Actions

    private var bulkActionsSection: some View {
        Section("Bulk Actions") {
            Button { executeAllEnabled() } label: {
                Label("Run All Enabled Rules", systemImage: "play.fill")
            }
            .disabled(engine.rules.filter(\.isEnabled).isEmpty)
        }
    }

    // MARK: - Sheets

    private var runHistorySheet: some View {
        List {
            ForEach(runHistory) { entry in
                HStack {
                    Image(systemName: entry.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(entry.success ? .green : .red)
                    VStack(alignment: .leading) {
                        Text(entry.ruleName).font(.subheadline)
                        Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Run History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Clear") { runHistory.removeAll() }
            }
        }
    }

    private var exportRulesSheet: some View {
        Form {
            Section("Export") {
                LabeledContent("Rules", value: "\(engine.rules.count)")
                LabeledContent("Enabled", value: "\(engine.rules.filter(\.isEnabled).count)")
            }
            Section {
                Button("Copy to Clipboard") {
                    let lines = engine.rules.map { "\($0.name) — \($0.isEnabled ? "Enabled" : "Disabled") — \($0.runCount) runs" }
                    UIPasteboard.general.string = lines.joined(separator: "\n")
                }
                .frame(maxWidth: .infinity).bold()
                .buttonStyle(.borderedProminent)
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("Export Rules")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Helpers

    private func deleteRules(at offsets: IndexSet) {
        let rules = filteredRules
        offsets.forEach { index in
            engine.remove(id: rules[index].id)
        }
    }

    private func enableAllRules() {
        for i in engine.rules.indices {
            engine.rules[i].isEnabled = true
        }
    }

    private func disableAllRules() {
        for i in engine.rules.indices {
            engine.rules[i].isEnabled = false
        }
    }

    private func executeAllEnabled() {
        for rule in engine.rules where rule.isEnabled {
            engine.trigger(rule)
            runHistory.insert(AutomationRunEntry(ruleName: rule.name, success: true, timestamp: Date()), at: 0)
        }
    }
}

private enum AutomationFilter: String {
    case all, enabled, disabled
}

private struct AutomationRunEntry: Identifiable {
    let id = UUID()
    let ruleName: String
    let success: Bool
    let timestamp: Date
}

// MARK: - Private Subviews

private struct AutomationRuleRow: View {
    let rule: SDKAutomationRule
    @ObservedObject var engine: SDKAutomationEngine
    var onRun: (() -> Void)?

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

            HStack {
                Button {
                    engine.trigger(rule)
                    onRun?()
                } label: {
                    Label("Run Now", systemImage: "play.fill")
                        .font(.caption2)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(!rule.isEnabled)

                Spacer()

                Text(rule.isEnabled ? "Active" : "Paused")
                    .font(.caption2)
                    .foregroundStyle(rule.isEnabled ? .green : .secondary)
            }
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
