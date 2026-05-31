import SwiftUI

struct LogDrainConfigView: View {
    @State private var showingAddDrain = false
    @State private var drainUrl = "https://"
    @State private var drainType: DrainType = .http

    enum DrainType: String, CaseIterable {
        case http = "HTTP POST"
        case syslog = "Syslog"
        case datadog = "Datadog"
        case logflare = "Logflare"
    }

    var body: some View {
        List {
            Section("Streaming Configuration") {
                Text("Configure external endpoints to stream your application logs in real-time for long-term retention and external analysis.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section("Active Drains") {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Default Data Lake").font(.subheadline.bold())
                        Text("https://ingest.internal.lake").font(.caption).monospaced().foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("ACTIVE").font(.system(size: 8, weight: .bold)).foregroundStyle(.green)
                }
            }

            Section {
                Button { showingAddDrain = true } label: { Label("Add Log Drain", systemImage: "plus.circle") }
            }
        }
        .navigationTitle("Log Drains")
        .sheet(isPresented: $showingAddDrain) {
            NavigationStack {
                Form {
                    Section("Drain Details") {
                        TextField("Endpoint URL", text: $drainUrl)
                        Picker("Type", selection: $drainType) {
                            ForEach(DrainType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                    }
                }
                .navigationTitle("New Drain")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAddDrain = false } }
                    ToolbarItem(placement: .confirmationAction) { Button("Add") { showingAddDrain = false } }
                }
            }
        }
    }
}
