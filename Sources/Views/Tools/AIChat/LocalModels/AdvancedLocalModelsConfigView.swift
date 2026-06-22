import SwiftUI

struct AdvancedLocalModelsConfigView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var config: LocalModelConfig

    var body: some View {
        Form {
            Section {
                settingSlider(label: "Temperature", value: $config.temperature, range: 0...2, step: 0.1, specifier: "%.1f")
                Stepper("Max Tokens: \(config.maxTokens)", value: $config.maxTokens, in: 128...128000, step: 128)
                settingSlider(label: "Top-P", value: $config.topP, range: 0...1, step: 0.05, specifier: "%.2f")
            } header: {
                Text("Core Parameters")
            }

            Section {
                Toggle("Enable Streaming", isOn: $config.isStreamingEnabled)
                Stepper("Timeout: \(Int(config.timeout))s", value: $config.timeout, in: 5...600, step: 5)
            } header: {
                Text("Interaction")
            }

            Section {
                settingSlider(label: "Repeat Penalty", value: $config.repeatPenalty, range: 0...2, step: 0.05, specifier: "%.2f")
                Stepper("Context Length: \(config.contextLength)", value: $config.contextLength, in: 512...128000, step: 512)
                Stepper("GPU Layers: \(config.numGpu)", value: $config.numGpu, in: 0...128, step: 1)
            } header: {
                Text("Performance & Sampling")
            }
        }
        .navigationTitle("Advanced Settings")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }

    private func settingSlider(label: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, specifier: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(label): \(value.wrappedValue, specifier: specifier)")
            Slider(value: value, in: range, step: step)
        }
    }
}
