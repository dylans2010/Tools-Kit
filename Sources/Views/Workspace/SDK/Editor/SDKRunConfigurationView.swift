import SwiftUI

struct SDKRunConfigurationView: View {
    @StateObject private var state = SDKRuntimeWorkspaceState.shared

    var body: some View {
        List {
            Section {
                ForEach($state.runConfigurations) { $config in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "terminal")
                                .foregroundStyle(.blue)
                            TextField("Configuration Name", text: $config.name)
                                .font(.headline)
                            Spacer()

                            if state.selectedRunConfigurationID == config.id {
                                SDKStatusPill("ACTIVE", systemImage: "play.fill", color: .blue)
                            } else {
                                Button {
                                    state.selectedRunConfigurationID = config.id
                                    state.saveSnapshot()
                                } label: {
                                    Text("SELECT")
                                        .font(.system(size: 10, weight: .bold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.primary.opacity(0.05), in: Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            configRow(label: "Mode", icon: "gearshape") {
                                Picker("Mode", selection: $config.mode) {
                                    ForEach(SDKRunConfiguration.Mode.allCases, id: \.self) { mode in
                                        Text(mode.rawValue).tag(mode)
                                    }
                                }
                                .pickerStyle(.menu)
                                .labelsHidden()
                            }

                            configRow(label: "Preset", icon: "slider.horizontal.3") {
                                TextField("Default", text: $config.environmentPreset)
                                    .multilineTextAlignment(.trailing)
                            }

                            configRow(label: "Simulation", icon: "cpu") {
                                Toggle("", isOn: $config.parallelSimulation)
                                    .labelsHidden()
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Label("Scoped Execution", systemImage: "scope")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.secondary)

                                TextField("Enter scopes (comma separated)", text: Binding(
                                    get: { config.scopedExecution.joined(separator: ", ") },
                                    set: { config.scopedExecution = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty } }
                                ))
                                .font(.system(size: 12, design: .monospaced))
                                .padding(8)
                                .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }
                    .padding(.vertical, 8)
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
                    state.runConfigurations.append(SDKRunConfiguration(name: "New Configuration"))
                    state.saveSnapshot()
                } label: {
                    HStack {
                        Spacer()
                        Label("Add Configuration", systemImage: "plus.circle.fill")
                            .font(.headline)
                        Spacer()
                    }
                }
                .listRowBackground(Color.blue.opacity(0.1))
                .foregroundStyle(.blue)
            }
        }
        .listStyle(.insetGrouped)
        .onChange(of: state.runConfigurations) { _, _ in
            state.saveSnapshot()
            state.recalculateDiagnostics()
        }
        .navigationTitle("Run Configuration")
    }

    private func configRow<Content: View>(label: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Label(label, systemImage: icon)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Spacer()
            content()
                .font(.system(size: 12))
        }
    }
}
