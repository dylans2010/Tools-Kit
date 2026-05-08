import SwiftUI

// MARK: - Code Intelligence View

struct CodeIntelligenceView: View {
    @StateObject private var service = RepoIntelligenceService.shared
    @State private var activeTab = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("Tab", selection: $activeTab) {
                Text("Security").tag(0)
                Text("Code Smells").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()

            if service.isScanning {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Scanning repository…").font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if activeTab == 0 {
                securityTab
            } else {
                smellsTab
            }
        }
        .navigationTitle("Code Intelligence")
        .toolbar {
            Button {
                // In a real scenario, provide repo files.
                // Demo scan with placeholder files.
                service.scanContent(files: [
                    (path: "Config.swift", content: "let api_key = \"sk-12345678\""),
                    (path: "Networking.swift", content: """
                    import Foundation
                    // Large file simulation
                    \(Array(repeating: "// line", count: 600).joined(separator: "\n"))
                    let password = \"hardcoded123\"
                    """),
                    (path: "Models.swift", content: "struct User { let id: UUID }"),
                ])
            } label: {
                Label("Scan", systemImage: "magnifyingglass")
            }
        }
    }

    private var securityTab: some View {
        Group {
            if service.securityIssues.isEmpty {
                ContentUnavailableView("No Security Issues", systemImage: "lock.shield.fill", description: Text("Tap Scan to analyze your repository files."))
            } else {
                List(service.securityIssues) { issue in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: severityIcon(issue.severity))
                                .foregroundStyle(severityColor(issue.severity))
                            Text(issue.description).font(.subheadline.bold())
                            Spacer()
                            Text(issue.severity.rawValue).font(.caption2)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(severityColor(issue.severity).opacity(0.15))
                                .clipShape(Capsule())
                        }
                        Text(URL(fileURLWithPath: issue.filePath).lastPathComponent)
                            .font(.caption).foregroundStyle(.secondary)
                        Text("Line \(issue.line)").font(.caption2).foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private var smellsTab: some View {
        Group {
            if service.codeSmells.isEmpty {
                ContentUnavailableView("No Code Smells", systemImage: "nose.fill", description: Text("Tap Scan to detect code issues."))
            } else {
                List(service.codeSmells) { smell in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: smellIcon(smell.type))
                                .foregroundStyle(.orange)
                            Text(smell.type.rawValue).font(.subheadline.bold())
                        }
                        Text(smell.description).font(.caption).foregroundStyle(.secondary)
                        Text(URL(fileURLWithPath: smell.filePath).lastPathComponent).font(.caption2).foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private func severityIcon(_ s: RepoIntelligenceService.IssueSeverity) -> String {
        switch s { case .critical: return "exclamationmark.3"; case .high: return "exclamationmark.2"; case .medium: return "exclamationmark"; case .low: return "info.circle" }
    }
    private func severityColor(_ s: RepoIntelligenceService.IssueSeverity) -> Color {
        switch s { case .critical: return .red; case .high: return .orange; case .medium: return .yellow; case .low: return .blue }
    }
    private func smellIcon(_ t: RepoIntelligenceService.SmellType) -> String {
        switch t { case .duplicate: return "doc.on.doc"; case .largeFile: return "doc.badge.ellipsis"; case .unusedImport: return "link.badge.plus"; case .hardcodedValue: return "hammer" }
    }
}

// MARK: - Workflow Builder View

struct WorkflowBuilderView: View {
    @StateObject private var builder = WorkflowBuilderService.shared
    @State private var showingCreate = false
    @State private var selectedWorkflow: WorkflowBuilderService.WorkflowDefinition?
    @State private var simLog: [String] = []
    @State private var showingSimLog = false

    var body: some View {
        List {
            Section {
                Button(action: { showingCreate = true }) {
                    Label("New Workflow", systemImage: "plus.rectangle.on.rectangle")
                }
                .foregroundStyle(.blue)
            }

            Section {
                if builder.workflows.isEmpty {
                    Text("No workflows yet. Create one above.").foregroundStyle(.secondary).font(.caption)
                } else {
                    ForEach(builder.workflows) { wf in
                        WorkflowBuilderRow(workflow: wf, onSelect: { selectedWorkflow = wf }, onSimulate: {
                            simLog = builder.simulate(workflowID: wf.id)
                            showingSimLog = true
                        })
                    }
                    .onDelete { offsets in
                        offsets.map { builder.workflows[$0].id }.forEach { builder.deleteWorkflow(id: $0) }
                    }
                }
            } header: {
                Text("My Workflows (\(builder.workflows.count))")
            }
        }
        .navigationTitle("Workflow Builder")
        .sheet(isPresented: $showingCreate) {
            CreateWorkflowView()
        }
        .sheet(item: $selectedWorkflow) { (wf: WorkflowBuilderService.WorkflowDefinition) in
            WorkflowEditorView(workflowID: wf.id)
        }
        .sheet(isPresented: $showingSimLog) {
            SimulationLogView(log: simLog)
        }
    }
}

struct WorkflowBuilderRow: View {
    let workflow: WorkflowBuilderService.WorkflowDefinition
    let onSelect: () -> Void
    let onSimulate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(workflow.name).font(.subheadline.bold())
                Spacer()
                Text("\(workflow.jobs.count) job(s)").font(.caption2).foregroundStyle(.secondary)
            }
            Text("Triggers: \(workflow.triggers.joined(separator: ", "))").font(.caption).foregroundStyle(.secondary)
            if let last = workflow.lastSimulated {
                Text("Last simulated: \(last, style: .relative)").font(.caption2).foregroundStyle(.tertiary)
            }
            HStack(spacing: 12) {
                Button("Edit", action: onSelect)
                    .font(.caption.bold()).foregroundStyle(.blue)
                Button("Dry Run", action: onSimulate)
                    .font(.caption.bold()).foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 4)
    }
}

struct CreateWorkflowView: View {
    @StateObject private var builder = WorkflowBuilderService.shared
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var pushTrigger = true
    @State private var prTrigger = false
    @State private var scheduleTrigger = false

    var body: some View {
        NavigationStack {
            Form {
                Section { TextField("My Workflow", text: $name) } header: {
                    Text("Name")
                }
                Section {
                    Toggle("push", isOn: $pushTrigger)
                    Toggle("pull_request", isOn: $prTrigger)
                    Toggle("schedule", isOn: $scheduleTrigger)
                } header: {
                    Text("Triggers")
                }
            }
            .navigationTitle("New Workflow")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        var triggers: [String] = []
                        if pushTrigger { triggers.append("push") }
                        if prTrigger { triggers.append("pull_request") }
                        if scheduleTrigger { triggers.append("schedule") }
                        builder.createWorkflow(name: name, triggers: triggers.isEmpty ? ["push"] : triggers)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

struct WorkflowEditorView: View {
    let workflowID: UUID
    @StateObject private var builder = WorkflowBuilderService.shared
    @Environment(\.dismiss) var dismiss
    @State private var yamlOutput = ""

    private var workflow: WorkflowBuilderService.WorkflowDefinition? {
        builder.workflows.first { $0.id == workflowID }
    }

    var body: some View {
        NavigationStack {
            List {
                if let wf = workflow {
                    Section {
                        ForEach(wf.triggers, id: \.self) { trigger in
                            Label(trigger, systemImage: "bolt.fill")
                        }
                    } header: {
                        Text("Triggers")
                    }
                    Section {
                        ForEach(wf.jobs) { job in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(job.name).font(.subheadline.bold())
                                Text("runs-on: \(job.runsOn)").font(.caption).foregroundStyle(.secondary)
                                Text("\(job.steps.count) step(s)").font(.caption2).foregroundStyle(.tertiary)
                            }
                        }
                    } header: {
                        Text("Jobs")
                    }
                    Section {
                        Button("Generate YAML Preview") {
                            yamlOutput = builder.exportYAML(workflowID: workflowID)
                        }
                        .foregroundStyle(.blue)
                        if !yamlOutput.isEmpty {
                            ScrollView {
                                Text(yamlOutput)
                                    .font(.system(.caption, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(8)
                            }
                            .frame(maxHeight: 200)
                            .background(Color(uiColor: .secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    } header: {
                        Text("Export YAML")
                    }
                }
            }
            .navigationTitle(workflow?.name ?? "Workflow")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
        }
    }
}

struct SimulationLogView: View {
    let log: [String]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(log, id: \.self) { line in
                        Text(line)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(line.contains("✅") ? .green : line.contains("▶") ? .blue : .primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
            }
            .navigationTitle("Dry Run Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
        }
    }
}
