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
    }

    private func deleteDrain(at offsets: IndexSet) {
        for index in offsets {
            let drain = logService.logDrains[index]
            Task { try? await logService.deleteLogDrain(id: drain.id) }
        }
    }
}
