import SwiftUI

struct LogDrainConfigView: View {
    @ObservedObject var logService = DeveloperLogService.shared
    @State private var showingAdd = false
    @State private var newName = ""
    @State private var newURL = ""
    @State private var selectedFormat: String = "JSON"

    var body: some View {
        List {
            Section("External Log Drains") {
                if logService.logDrains.isEmpty {
                    Text("No log drains configured. Stream your logs to external providers for long-term storage and analysis.").foregroundStyle(.secondary)
                } else {
                    ForEach(logService.logDrains) { drain in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(drain.name).font(.headline)
                            Text(drain.targetURL).font(.caption).foregroundStyle(.secondary)
                        }
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
                Section("Drain Details") {
                    TextField("Name", text: $newName)
                    TextField("Target URL", text: $newURL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
                Section("Configuration") {
                    Picker("Format", selection: $selectedFormat) {
                        Text("JSON").tag("JSON")
                        Text("Syslog").tag("Syslog")
                        Text("Plain Text").tag("Plain Text")
                    }
                }
            }
            .navigationTitle("New Log Drain")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAdd = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        saveDrain()
                    }
                    .disabled(newName.isEmpty || newURL.isEmpty)
                }
            }
        }
    }

    private func saveDrain() {
        let drain = LogDrain(name: newName, targetURL: newURL)
        Task {
            try? await logService.saveLogDrain(drain)
            await MainActor.run {
                showingAdd = false
                newName = ""
                newURL = ""
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
