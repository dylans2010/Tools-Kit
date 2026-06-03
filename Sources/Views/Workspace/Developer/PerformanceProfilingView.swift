import SwiftUI

struct PerformanceProfilingView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared

    var body: some View {
        List {
            Section("Trace Analysis") {
                if store.performanceTraces.isEmpty {
                    Text("No traces captured.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(store.performanceTraces) { trace in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(trace.operation).font(.subheadline.bold())
                                Text(trace.duration).font(.caption.monospaced()).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(trace.impact)
                                .font(.system(size: 8, weight: .black))
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(trace.impact == "High" ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                                .foregroundStyle(trace.impact == "High" ? .red : .blue)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            Section {
                Button("Capture Live Performance Trace") {
                    var current = store.performanceTraces
                    current.append(PerformanceTrace(operation: "New Trace", duration: "15ms", impact: "Low"))
                    store.savePerformanceTraces(current)
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Performance Profile")
        .onAppear {
            if store.performanceTraces.isEmpty {
                store.savePerformanceTraces([
                    PerformanceTrace(operation: "App Startup", duration: "1.2s", impact: "High"),
                    PerformanceTrace(operation: "Data Sync", duration: "240ms", impact: "Low")
                ])
            }
        }
    }
}
