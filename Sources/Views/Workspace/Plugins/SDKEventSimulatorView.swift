import SwiftUI

struct SDKEventSimulatorView: View {
    @State private var selectedType: SDKScope = .notes
    @State private var eventMessage = ""

    var body: some View {
        Form {
            Section("Trigger Data Event") {
                Picker("Data Type", selection: $selectedType) {
                    ForEach(SDKScope.allCases, id: \.self) { type in
                        Text(type.rawValue.capitalized).tag(type)
                    }
                }

                TextField("Event Message", text: $eventMessage)

                Button("Simulate Create") {
                    simulateEvent(type: .create)
                }

                Button("Simulate Update") {
                    simulateEvent(type: .update)
                }

                Button("Simulate Delete") {
                    simulateEvent(type: .delete)
                }
                .foregroundStyle(.red)
            }
        }
        .navigationTitle("Event Simulator")
    }

    private enum EventType {
        case create, update, delete
    }

    private func simulateEvent(type: EventType) {
        let msg = eventMessage.isEmpty ? "SDK Simulation" : eventMessage
        SDKConsoleView.LogBus.shared.log("Simulated \(type) on \(selectedType.rawValue): \(msg)", type: .info)
        // In a real implementation, this would push to the real PluginEventBus
    }
}
