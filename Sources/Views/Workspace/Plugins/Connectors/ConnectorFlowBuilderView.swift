import SwiftUI

struct ConnectorFlowBuilderView: View {
    @State var connector: ConnectorDefinition
    @StateObject private var manager = ConnectorManager.shared

    @State private var steps: [FlowStep]
    @State private var showingTemplates = false
    @State private var showingValidation = false
    @State private var validationErrors: [String] = []
    @State private var showingSaveConfirmation = false
    @State private var hasUnsavedChanges = false
    @State private var showingJSONExport = false
    @State private var exportedJSON = ""

    init(connector: ConnectorDefinition) {
        self.connector = connector
        _steps = State(initialValue: connector.flow.steps)
    }

    var body: some View {
        List {
            if !steps.isEmpty {
                flowSummarySection
            }
            workflowPipelineSection
            addStepSection
            if !validationErrors.isEmpty {
                validationSection
            }
            actionsSection
        }
        .navigationTitle("Flow Builder")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                flowToolbarMenu
            }
        }
        .sheet(isPresented: $showingTemplates) {
            templatePickerSheet
        }
        .sheet(isPresented: $showingJSONExport) {
            jsonExportSheet
        }
        .alert("Workflow Saved", isPresented: $showingSaveConfirmation) {
            Button("OK") {}
        } message: {
            Text("Your workflow with \(steps.count) steps has been saved successfully.")
        }
    }

    // MARK: - Flow Summary

    private var flowSummarySection: some View {
        Section {
            HStack(spacing: 16) {
                flowStat(label: "Steps", value: "\(steps.count)", color: .blue)
                flowStat(label: "Triggers", value: "\(steps.filter { $0.type == .trigger }.count)", color: .orange)
                flowStat(label: "Actions", value: "\(steps.filter { $0.type == .action }.count)", color: .green)
                flowStat(label: "Conditions", value: "\(steps.filter { $0.type == .condition }.count)", color: .purple)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                        HStack(spacing: 4) {
                            stepIcon(step.type)
                                .font(.caption2)
                            Text(step.type.rawValue.prefix(4).uppercased())
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(stepColor(step.type).opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                        if index < steps.count - 1 {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Workflow Pipeline

    private var workflowPipelineSection: some View {
        Section("Workflow Pipeline") {
            if steps.isEmpty {
                emptyPipelineView
            } else {
                ForEach($steps) { $step in
                    stepRow(step: $step)
                        .contextMenu {
                            Button {
                                duplicateStep(step.wrappedValue)
                            } label: {
                                Label("Duplicate", systemImage: "doc.on.doc")
                            }

                            if step.wrappedValue.type != .trigger {
                                Button {
                                    toggleStepEnabled(step: &step.wrappedValue)
                                } label: {
                                    Label(
                                        step.wrappedValue.config["disabled"] == "true" ? "Enable Step" : "Disable Step",
                                        systemImage: step.wrappedValue.config["disabled"] == "true" ? "checkmark.circle" : "xmark.circle"
                                    )
                                }
                            }

                            Divider()

                            Button(role: .destructive) {
                                if let index = steps.firstIndex(where: { $0.id == step.wrappedValue.id }) {
                                    steps.remove(at: index)
                                    hasUnsavedChanges = true
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
                .onMove { indices, newOffset in
                    steps.move(fromOffsets: indices, toOffset: newOffset)
                    hasUnsavedChanges = true
                }
                .onDelete { indices in
                    steps.remove(atOffsets: indices)
                    hasUnsavedChanges = true
                }
            }
        }
    }

    private var emptyPipelineView: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.triangle.branch")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            Text("No steps defined")
                .font(.headline)
            Text("Add a trigger to start building your automation pipeline, or use a template to get started quickly.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                Button {
                    addStep(.trigger)
                } label: {
                    Label("Add Trigger", systemImage: "bolt.fill")
                        .font(.caption)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)

                Button {
                    showingTemplates = true
                } label: {
                    Label("Use Template", systemImage: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    // MARK: - Add Step

    private var addStepSection: some View {
        Section {
            Menu {
                Button {
                    addStep(.trigger)
                } label: {
                    Label("Add Trigger", systemImage: "bolt.fill")
                }
                Button {
                    addStep(.condition)
                } label: {
                    Label("Add Condition", systemImage: "arrow.branch")
                }
                Button {
                    addStep(.action)
                } label: {
                    Label("Add Action", systemImage: "play.fill")
                }
                Button {
                    addStep(.delay)
                } label: {
                    Label("Add Delay", systemImage: "clock.fill")
                }
            } label: {
                Label("Add Step", systemImage: "plus.circle")
            }
        }
    }

    // MARK: - Validation

    private var validationSection: some View {
        Section("Validation Issues") {
            ForEach(validationErrors, id: \.self) { error in
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
    }

    // MARK: - Actions

    private var actionsSection: some View {
        Section {
            Button {
                validateFlow()
            } label: {
                Label("Validate Flow", systemImage: "checkmark.shield")
            }

            Button("Save Workflow") {
                connector.flow = ConnectorFlow(steps: steps)
                connector.updatedAt = Date()
                manager.updateConnector(connector)
                hasUnsavedChanges = false
                showingSaveConfirmation = true
            }
            .frame(maxWidth: .infinity)
            .bold()
            .disabled(steps.isEmpty)

            Button {
                exportFlowAsJSON()
            } label: {
                Label("Export as JSON", systemImage: "square.and.arrow.up")
            }
            .disabled(steps.isEmpty)
        }
    }

    // MARK: - Toolbar Menu

    private var flowToolbarMenu: some View {
        Menu {
            Button {
                showingTemplates = true
            } label: {
                Label("Templates", systemImage: "doc.on.doc")
            }

            Button {
                steps = []
                hasUnsavedChanges = true
            } label: {
                Label("Clear All Steps", systemImage: "trash")
            }

            EditButton()
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }

    // MARK: - Step Row

    private func stepRow(step: Binding<FlowStep>) -> some View {
        let isDisabled = step.wrappedValue.config["disabled"] == "true"

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                stepIcon(step.wrappedValue.type)
                Text(step.wrappedValue.type.rawValue.capitalized)
                    .font(.headline)
                Spacer()

                if isDisabled {
                    Text("DISABLED")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.15))
                        .foregroundColor(.secondary)
                        .clipShape(Capsule())
                }

                if let index = steps.firstIndex(where: { $0.id == step.wrappedValue.id }) {
                    Text("#\(index + 1)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            switch step.wrappedValue.type {
            case .trigger:
                TextField("Trigger Name (e.g. Daily Sync)", text: Binding(
                    get: { step.wrappedValue.config["name"] ?? "" },
                    set: { step.wrappedValue.config["name"] = $0; hasUnsavedChanges = true }
                ))
                TextField("Event (e.g. note.created, schedule.daily)", text: Binding(
                    get: { step.wrappedValue.config["event"] ?? "" },
                    set: { step.wrappedValue.config["event"] = $0; hasUnsavedChanges = true }
                ))
                .font(.system(.caption, design: .monospaced))
            case .condition:
                TextField("JS Condition (e.g. response.status == 200)", text: Binding(
                    get: { step.wrappedValue.config["js_condition"] ?? "" },
                    set: { step.wrappedValue.config["js_condition"] = $0; hasUnsavedChanges = true }
                ))
                .font(.system(.caption, design: .monospaced))

                TextField("Description (optional)", text: Binding(
                    get: { step.wrappedValue.config["description"] ?? "" },
                    set: { step.wrappedValue.config["description"] = $0; hasUnsavedChanges = true }
                ))
                .font(.caption)
            case .action:
                Picker("Endpoint", selection: Binding(
                    get: { step.wrappedValue.config["endpointID"] ?? "" },
                    set: { step.wrappedValue.config["endpointID"] = $0; hasUnsavedChanges = true }
                )) {
                    Text("Select Endpoint").tag("")
                    ForEach(connector.endpoints) { ep in
                        Text("\(ep.method) \(ep.path)").tag(ep.id.uuidString)
                    }
                }

                TextField("Action Label (optional)", text: Binding(
                    get: { step.wrappedValue.config["name"] ?? "" },
                    set: { step.wrappedValue.config["name"] = $0; hasUnsavedChanges = true }
                ))
                .font(.caption)
            case .delay:
                HStack {
                    Text("Seconds:")
                    TextField("0", text: Binding(
                        get: { step.wrappedValue.config["seconds"] ?? "0" },
                        set: { step.wrappedValue.config["seconds"] = $0; hasUnsavedChanges = true }
                    ))
                    .keyboardType(.numberPad)
                }

                if let seconds = step.wrappedValue.config["seconds"], let secs = Double(seconds), secs > 0 {
                    Text("Will pause for \(seconds) second(s) before continuing.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .opacity(isDisabled ? 0.5 : 1.0)
    }

    // MARK: - Template Picker

    private var templatePickerSheet: some View {
        NavigationView {
            List {
                Section("Starter Templates") {
                    Button {
                        applyTemplate(name: "Basic API Sync", steps: [
                            FlowStep(type: .trigger, config: ["name": "Scheduled Sync", "event": "schedule.hourly"]),
                            FlowStep(type: .action, config: ["name": "Fetch Data"]),
                            FlowStep(type: .delay, config: ["seconds": "1"])
                        ])
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Basic API Sync")
                                .font(.headline)
                            Text("Trigger -> Action -> Delay")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Button {
                        applyTemplate(name: "Conditional Webhook", steps: [
                            FlowStep(type: .trigger, config: ["name": "Webhook Received", "event": "webhook.incoming"]),
                            FlowStep(type: .condition, config: ["js_condition": "payload.type == 'update'", "description": "Check event type"]),
                            FlowStep(type: .action, config: ["name": "Process Update"]),
                            FlowStep(type: .action, config: ["name": "Send Notification"])
                        ])
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Conditional Webhook")
                                .font(.headline)
                            Text("Trigger -> Condition -> Action -> Action")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Button {
                        applyTemplate(name: "Rate-Limited Batch", steps: [
                            FlowStep(type: .trigger, config: ["name": "Batch Process", "event": "schedule.daily"]),
                            FlowStep(type: .action, config: ["name": "Fetch Batch"]),
                            FlowStep(type: .delay, config: ["seconds": "2"]),
                            FlowStep(type: .action, config: ["name": "Process Items"]),
                            FlowStep(type: .delay, config: ["seconds": "1"]),
                            FlowStep(type: .action, config: ["name": "Update Status"])
                        ])
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Rate-Limited Batch")
                                .font(.headline)
                            Text("Trigger -> Action -> Delay -> Action -> Delay -> Action")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Flow Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingTemplates = false }
                }
            }
        }
    }

    // MARK: - JSON Export

    private var jsonExportSheet: some View {
        NavigationView {
            ScrollView {
                Text(exportedJSON)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGroupedBackground))
                    .cornerRadius(8)
                    .padding()
            }
            .navigationTitle("Flow JSON")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showingJSONExport = false }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        UIPasteboard.general.string = exportedJSON
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func stepIcon(_ type: FlowStep.StepType) -> some View {
        let name: String
        let color: Color
        switch type {
        case .trigger: name = "bolt.fill"; color = .orange
        case .condition: name = "arrow.branch"; color = .purple
        case .action: name = "play.fill"; color = .blue
        case .delay: name = "clock.fill"; color = .gray
        }
        return Image(systemName: name).foregroundColor(color)
    }

    private func stepColor(_ type: FlowStep.StepType) -> Color {
        switch type {
        case .trigger: return .orange
        case .condition: return .purple
        case .action: return .blue
        case .delay: return .gray
        }
    }

    private func flowStat(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func addStep(_ type: FlowStep.StepType) {
        steps.append(FlowStep(type: type, config: [:]))
        hasUnsavedChanges = true
    }

    private func duplicateStep(_ step: FlowStep) {
        let newStep = FlowStep(type: step.type, config: step.config)
        if let index = steps.firstIndex(where: { $0.id == step.id }) {
            steps.insert(newStep, at: index + 1)
        } else {
            steps.append(newStep)
        }
        hasUnsavedChanges = true
    }

    private func toggleStepEnabled(step: inout FlowStep) {
        if step.config["disabled"] == "true" {
            step.config.removeValue(forKey: "disabled")
        } else {
            step.config["disabled"] = "true"
        }
        hasUnsavedChanges = true
    }

    private func applyTemplate(name: String, steps templateSteps: [FlowStep]) {
        steps = templateSteps
        hasUnsavedChanges = true
        showingTemplates = false
    }

    private func validateFlow() {
        validationErrors = []

        if steps.isEmpty {
            validationErrors.append("Flow has no steps.")
            return
        }

        if steps.first?.type != .trigger {
            validationErrors.append("Flow should start with a Trigger step.")
        }

        for (index, step) in steps.enumerated() {
            switch step.type {
            case .trigger:
                if (step.config["name"] ?? "").isEmpty {
                    validationErrors.append("Step #\(index + 1): Trigger is missing a name.")
                }
            case .condition:
                if (step.config["js_condition"] ?? "").isEmpty {
                    validationErrors.append("Step #\(index + 1): Condition has no JS expression.")
                }
            case .action:
                if (step.config["endpointID"] ?? "").isEmpty && connector.endpoints.isEmpty {
                    validationErrors.append("Step #\(index + 1): Action has no endpoint. Add endpoints first.")
                }
            case .delay:
                let seconds = Double(step.config["seconds"] ?? "0") ?? 0
                if seconds <= 0 {
                    validationErrors.append("Step #\(index + 1): Delay should be greater than 0 seconds.")
                }
            }
        }

        if validationErrors.isEmpty {
            validationErrors = []
        }
    }

    private func exportFlowAsJSON() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(ConnectorFlow(steps: steps)),
           let json = String(data: data, encoding: .utf8) {
            exportedJSON = json
        } else {
            exportedJSON = "{ \"error\": \"Failed to encode flow\" }"
        }
        showingJSONExport = true
    }
}
