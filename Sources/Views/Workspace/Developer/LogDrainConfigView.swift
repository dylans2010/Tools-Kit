import SwiftUI

struct LogDrainConfigView: View {
    @ObservedObject var logService = DeveloperLogService.shared
    @State private var showingAdd = false
    @State private var newName = ""
    @State private var newURL = ""

    var body: some View {
        List {
            Section("External Log Drains") {
                if logService.logDrains.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("No log drains configured.").font(.subheadline.bold())
                        Text("Stream your logs to external providers for long-term storage and analysis.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                } else {
                    ForEach(logService.logDrains) { drain in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(drain.name).font(.subheadline.bold())
                            Text(drain.targetURL).font(.caption).monospaced().foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: deleteDrain)
                }
            }
        }
        .navigationTitle("Log Drains")
        .toolbar {
            Button { showingAdd = true } label: { Image(systemName: "plus") }
        }
        .sheet(isPresented: $showingAdd) {
            addDrainSheet
        }
    }

    private var addDrainSheet: some View {
        NavigationStack {
            Form {
                Section("Provider Details") {
                    TextField("Configuration Name", text: $newName)
                    TextField("Endpoint URL", text: $newURL)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
            }
            .navigationTitle("New Log Drain")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAdd = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Configure") {
                        Task {
                            try? await logService.createLogDrain(name: newName, targetURL: newURL)
                            await MainActor.run {
                                showingAdd = false
                                newName = ""
                                newURL = ""
                            }
                        }
                    }
                    .disabled(newName.isEmpty || newURL.isEmpty)
                }
            }
        }
    }

    private func deleteDrain(at offsets: IndexSet) {
        for index in offsets {
            let drain = logService.logDrains[index]
            Task { try? await logService.deleteLogDrain(id: drain.id) }
        }
    }
}
