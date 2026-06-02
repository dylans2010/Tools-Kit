import SwiftUI

struct APIRateLimitConfigView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared
    @State private var showingAddLimit = false
    @State private var endpoint = ""
    @State private var limit = 60
    @State private var window = 60

    var body: some View {
        List {
            Section("Global Controls") {
                Toggle("Enforce Rate Limits", isOn: .constant(true))
                Toggle("Auto-Scale on Burst", isOn: .constant(false))
            }

            Section {
                Button(action: { showingAddLimit = true }) {
                    Label("Add Endpoint Limit", systemImage: "timer")
                }
            }

            Section("Active Limits") {
                if store.rateLimits.isEmpty {
                    Text("No custom rate limits configured.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.rateLimits) { rateLimit in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(rateLimit.endpoint)
                                    .font(.subheadline.bold())
                                    .fontDesign(.monospaced)
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { rateLimit.isEnabled },
                                    set: { _ in toggleLimit(rateLimit) }
                                ))
                                .labelsHidden()
                            }

                            HStack {
                                Label("\(rateLimit.limit) req", systemImage: "arrow.up.circle")
                                Label("\(rateLimit.windowSeconds)s", systemImage: "clock")
                                Spacer()
                                Text("CUSTOM")
                                    .font(.system(size: 8, weight: .black))
                                    .foregroundStyle(.blue)
                            }
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: deleteLimit)
                }
            }
        }
        .navigationTitle("Rate Limits")
        .sheet(isPresented: $showingAddLimit) {
            NavigationStack {
                Form {
                    Section("Endpoint") {
                        TextField("/api/v1/resource", text: $endpoint)
                    }
                    Section("Thresholds") {
                        Stepper("Limit: \(limit) requests", value: $limit, in: 1...10000)
                        Stepper("Window: \(window) seconds", value: $window, in: 1...3600)
                    }
                }
                .navigationTitle("New Limit")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAddLimit = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { saveLimit() }
                            .disabled(endpoint.isEmpty)
                    }
                }
            }
        }
    }

    private func saveLimit() {
        let newLimit = APIRateLimit(endpoint: endpoint, limit: limit, windowSeconds: window)
        var updated = store.rateLimits
        updated.append(newLimit)
        store.saveRateLimits(updated)

        endpoint = ""
        showingAddLimit = false
    }

    private func toggleLimit(_ limit: APIRateLimit) {
        var updated = store.rateLimits
        if let index = updated.firstIndex(where: { $0.id == limit.id }) {
            updated[index].isEnabled.toggle()
            store.saveRateLimits(updated)
        }
    }

    private func deleteLimit(at offsets: IndexSet) {
        var updated = store.rateLimits
        updated.remove(atOffsets: offsets)
        store.saveRateLimits(updated)
    }
}
