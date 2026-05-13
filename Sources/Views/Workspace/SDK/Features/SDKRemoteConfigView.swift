
import SwiftUI

struct SDKRemoteConfigView: View {
    @State private var fetchIntervalMinutes: Double = 60
    @State private var parameters: [ConfigParam] = []

    struct ConfigParam: Identifiable {
        let id = UUID()
        var key: String
        var value: String
    }

    var body: some View {
        List {
            Section("Update Policy") {
                VStack(alignment: .leading) {
                    Text("Fetch Interval: \(Int(fetchIntervalMinutes)) mins")
                    Slider(value: $fetchIntervalMinutes, in: 15...1440, step: 15)
                }
            }

            Section("Parameters") {
                if parameters.isEmpty {
                    Text("No remote parameters defined.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(parameters) { p in
                        HStack {
                            Text(p.key).monospaced()
                            Spacer()
                            Text(p.value).foregroundStyle(.secondary)
                        }
                    }
                }
                Button("Add Parameter", systemImage: "plus") { }
            }
        }
        .navigationTitle("Remote Config")
    }
}
