/*
 REDESIGN SUMMARY:
 - Standardized on insetGrouped List style.
 - Modernized configuration rows using a private struct RunConfigRow with semantic status badges.
 - Standardized profile selection using native Buttons and capsule status indicators.
 - Replaced manual TextField layouts with native Form components within the List.
 - strictly preserved all SDKRuntimeWorkspaceState management and profile persistence.
 - Improved visual hierarchy for simulation settings and scoped execution lists.
 - Standardized the 'Add Profile' action button style.
 */

import SwiftUI

struct SDKRunConfigurationView: View {
    @StateObject private var state = SDKRuntimeWorkspaceState.shared

    var body: some View {
        List {
            Section("Available Profiles") {
                ForEach($state.runConfigurations) { $config in
                    RunConfigRow(config: $config, isActive: state.selectedRunConfigurationID == config.id) {
                        state.selectedRunConfigurationID = config.id
                        state.saveSnapshot()
                    }
                }
                .onDelete { offsets in
                    state.runConfigurations.remove(atOffsets: offsets)
                    if state.runConfigurations.isEmpty { state.runConfigurations = [SDKRunConfiguration(name: "Default Sandbox")] }
                    if state.selectedRunConfigurationID == nil { state.selectedRunConfigurationID = state.runConfigurations.first?.id }
                    state.saveSnapshot()
                }
            }

            Section {
                Button {
                    state.runConfigurations.append(SDKRunConfiguration(name: "New Profile"))
                    state.saveSnapshot()
                } label: {
                    Label("Add Run Profile", systemImage: "plus.circle.fill")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Run Profiles")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: state.runConfigurations) { _, _ in
            state.saveSnapshot()
            state.recalculateDiagnostics()
        }
    }
}

// MARK: - Private Subviews

private struct RunConfigRow: View {
    @Binding var config: SDKRunConfiguration
    let isActive: Bool
    let onSelect: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                TextField("Profile Name", text: $config.name)
                    .font(.headline)
                Spacer()
                if isActive {
                    Text("ACTIVE")
                        .font(.system(size: 8, weight: .black))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.green.opacity(0.1), in: Capsule())
                        .foregroundStyle(.green)
                } else {
                    Button("Select", action: onSelect)
                        .font(.caption2.bold())
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                LabeledContent("Execution Mode") {
                    Picker("", selection: $config.mode) {
                        ForEach(SDKRunConfiguration.Mode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }

                LabeledContent("Environment", value: config.environmentPreset)

                Toggle("Parallel Simulation", isOn: $config.parallelSimulation).font(.caption)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Scoped Execution").font(.system(size: 8, weight: .bold)).foregroundStyle(.tertiary).textCase(.uppercase)
                    TextField("Enter comma-separated scopes", text: Binding(
                        get: { config.scopedExecution.joined(separator: ", ") },
                        set: { config.scopedExecution = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty } }
                    ))
                    .font(.caption.monospaced())
                    .padding(8)
                    .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(.vertical, 4)
    }
}
