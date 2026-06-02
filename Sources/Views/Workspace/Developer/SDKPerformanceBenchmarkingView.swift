import SwiftUI

struct SDKPerformanceBenchmarkingView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared
    @State private var showingAdd = false
    @State private var name = ""
    @State private var value = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerView

                VStack(spacing: 1) {
                    if store.sdkBenchmarks.isEmpty {
                        Text("No benchmark results.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding()
                    } else {
                        ForEach(store.sdkBenchmarks) { result in
                            BenchmarkRow(result: result)
                            if result.id != store.sdkBenchmarks.last?.id {
                                Divider().padding(.leading, 44)
                            }
                        }
                    }
                }
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Button(action: { showingAdd = true }) {
                    Label("Add Result", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .navigationTitle("Performance")
        .background(Color(uiColor: .systemGroupedBackground))
        .sheet(isPresented: $showingAdd) {
            NavigationStack {
                Form {
                    TextField("Test Name", text: $name)
                    TextField("Result (e.g. 12ms)", text: $value)
                }
                .navigationTitle("New Result")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAdd = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { saveBenchmark() }
                            .disabled(name.isEmpty || value.isEmpty)
                    }
                }
            }
        }
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Benchmark Results")
                    .font(.headline)
            }
            Spacer()
            Image(systemName: "gauge.with.needle.fill")
                .font(.title)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 8)
    }

    private func saveBenchmark() {
        let new = SDKBenchmarkResult(name: name, value: value, delta: "0%", status: "Stable")
        var updated = store.sdkBenchmarks
        updated.append(new)
        store.saveSDKBenchmarks(updated)
        name = ""
        value = ""
        showingAdd = false
    }
}

private struct BenchmarkRow: View {
    let result: SDKBenchmarkResult

    var body: some View {
        HStack(spacing: 16) {
            Circle().fill(Color.green.opacity(0.1))
                .frame(width: 28, height: 28)
                .overlay(Image(systemName: "minus").font(.system(size: 10, weight: .bold)).foregroundStyle(.green))

            VStack(alignment: .leading, spacing: 2) {
                Text(result.name).font(.subheadline.bold())
                Text(result.value).font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            Text(result.delta)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.green)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.05))
                .clipShape(Capsule())
        }
        .padding()
    }
}
