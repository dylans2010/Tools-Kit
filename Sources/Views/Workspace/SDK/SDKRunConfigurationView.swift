import SwiftUI

struct SDKRunConfigurationView: View {
    @StateObject private var state = SDKRuntimeWorkspaceState.shared

    var body: some View {
        List {
            Section("Run Configurations") {
                ForEach($state.runConfigurations) { $config in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            TextField("Configuration name", text: $config.name)
                            Spacer()
                            Button {
                                state.selectedRunConfigurationID = config.id
                                state.saveSnapshot()
                            } label: {
                                Image(systemName: state.selectedRunConfigurationID == config.id ? "checkmark.circle.fill" : "circle")
                            }
                            .buttonStyle(.borderless)
                        }

                        Picker("Mode", selection: $config.mode) {
                            ForEach(SDKRunConfiguration.Mode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.menu)

                        TextField("Environment preset", text: $config.environmentPreset)
                        Toggle("Parallel run simulation", isOn: $config.parallelSimulation)
                        TextField("Scoped execution (comma-separated)", text: Binding(
                            get: { config.scopedExecution.joined(separator: ",") },
                            set: { config.scopedExecution = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty } }
                        ))
                        .font(.caption)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { offsets in
                    state.runConfigurations.remove(atOffsets: offsets)
                    if state.runConfigurations.isEmpty {
                        state.runConfigurations = [SDKRunConfiguration(name: "Default Sandbox")]
                    }
                    if state.selectedRunConfigurationID == nil {
                        state.selectedRunConfigurationID = state.runConfigurations.first?.id
                    }
                    state.saveSnapshot()
                }
            }

            Section {
                Button {
                    state.runConfigurations.append(SDKRunConfiguration(name: "Run Config \(state.runConfigurations.count + 1)"))
                    state.saveSnapshot()
                } label: {
                    Label("Add Configuration", systemImage: "plus")
                }
            }
        }
        .onChange(of: state.runConfigurations) { _, _ in
            state.saveSnapshot()
            state.recalculateDiagnostics()
        }
        .navigationTitle("Run Configuration")
    }
}
