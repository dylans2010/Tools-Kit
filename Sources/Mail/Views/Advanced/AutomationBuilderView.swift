import SwiftUI

/// Visual editor for building and editing multi-step automation pipelines.
struct AutomationBuilderView: View {
    @StateObject private var viewModel = AutomationBuilderViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.workspaceBackground.ignoresSafeArea()

            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Workflow Identity")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        TextField("e.g. Weekly Report Processing", text: $viewModel.workflowName)
                            .font(.headline)
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color.workspaceSurface)

                Section {
                    headerForSteps

                    if viewModel.steps.isEmpty {
                        Text("No steps added yet. Start building your automation.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 20)
                    } else {
                        ForEach($viewModel.steps) { $step in
                            StepRow(step: $step)
                        }
                        .onDelete(perform: viewModel.deleteStep)
                        .onMove(perform: moveSteps)
                    }

                    Button {
                        withAnimation {
                            viewModel.addStep()
                        }
                    } label: {
                        Label("Add Execution Step", systemImage: "plus.circle.fill")
                            .font(.subheadline.bold())
                    }
                }
                .listRowBackground(Color.workspaceSurface)

                Section {
                    Button {
                        viewModel.compileWorkflow()
                    } label: {
                        HStack {
                            Spacer()
                            if viewModel.isCompiling {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "bolt.fill")
                                Text("Compile & Activate")
                                    .fontWeight(.bold)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    .disabled(viewModel.workflowName.isEmpty || viewModel.steps.isEmpty || viewModel.isCompiling)
                    .buttonStyle(.borderedProminent)
                    .listRowInsets(EdgeInsets())
                }
                .listRowBackground(Color.clear)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Automation Builder")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .onChange(of: viewModel.isCompiling) { newValue in
            if !newValue && !viewModel.workflowName.isEmpty && !viewModel.steps.isEmpty {
                // Successfully compiled
                dismiss()
            }
        }
    }

    private var headerForSteps: some View {
        HStack {
            Text("Pipeline Steps")
                .font(.headline)
            Spacer()
            Text("\(viewModel.steps.count) total")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
    }

    private func moveSteps(from source: IndexSet, to destination: Int) {
        viewModel.steps.move(fromOffsets: source, toOffset: destination)
    }
}

struct StepRow: View {
    @Binding var step: WorkflowStep

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconForAction(step.actionType))
                    .foregroundStyle(.blue)
                TextField("Step Title", text: $step.title)
                    .font(.subheadline.bold())
            }

            TextField("Action details...", text: $step.description)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Picker("Action Type", selection: $step.actionType) {
                    Text("Manual").tag("manual")
                    Text("AI Processing").tag("ai")
                    Text("API Call").tag("api")
                    Text("Notify").tag("notify")
                }
                .pickerStyle(.segmented)
            }
        }
        .padding(.vertical, 4)
    }

    private func iconForAction(_ type: String) -> String {
        switch type {
        case "ai": return "sparkles"
        case "api": return "network"
        case "notify": return "bell.fill"
        default: return "hand.tap.fill"
        }
    }
}
