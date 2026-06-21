import SwiftUI

struct LMLinkModelsView: View {
    @StateObject private var connectionManager = LMConnectionManager.shared

    var body: some View {
        Group {
            if let device = connectionManager.selectedDevice {
                List {
                    Section(header: Text("Models on \(device.name)")) {
                        if device.models.isEmpty {
                            Text("No models found. Tap refresh to check again.")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(device.models) { model in
                                Button(action: {
                                    connectionManager.selectModel(model)
                                }) {
                                    HStack {
                                        LMModelRowView(model: model)
                                        Spacer()
                                        if connectionManager.selectedModel?.id == model.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "cpu")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("No device selected")
                        .font(.headline)
                    Text("Select a device in the Devices tab to see available models.")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Models")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    Task {
                        await connectionManager.fetchModelsForSelectedDevice()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(connectionManager.selectedDevice == nil)
            }
        }
    }
}
