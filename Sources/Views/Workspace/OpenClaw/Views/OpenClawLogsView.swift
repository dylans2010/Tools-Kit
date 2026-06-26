import SwiftUI

struct OpenClawLogsView: View {
    private var diagnostics = OpenClawDiagnosticsManager.shared

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 4) {
                ForEach(diagnostics.logs, id: \.self) { log in
                    Text(log)
                        .font(.system(.caption, design: .monospaced))
                        .padding(.horizontal)
                }
            }
        }
        .navigationTitle("System Logs")
        .toolbar {
            Button("Clear") {
                diagnostics.logs.removeAll()
            }
        }
    }
}
