import SwiftUI

struct SDKVersionManagerView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared
    @State private var showingAddVersion = false
    @State private var versionString = ""
    @State private var releaseNotes = ""
    @State private var selectedStatus: SDKVersion.SDKVersionStatus = .beta

    var body: some View {
        List {
            Section {
                Button(action: { showingAddVersion = true }) {
                    Label("Register New Version", systemImage: "tag.fill")
                }
            }

            Section("Release History") {
                if store.sdkVersions.isEmpty {
                    Text("No versions registered yet.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.sdkVersions.sorted(by: { $0.createdAt > $1.createdAt })) { version in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(version.versionString)
                                    .font(.system(.headline, design: .monospaced))
                                Spacer()
                                statusBadge(version.status)
                            }

                            Text(version.releaseNotes)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text(version.createdAt, style: .date)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: deleteVersion)
                }
            }
        }
        .navigationTitle("Version Manager")
        .sheet(isPresented: $showingAddVersion) {
            NavigationStack {
                Form {
                    Section("Version Info") {
                        TextField("Version (e.g. 1.2.0)", text: $versionString)
                        Picker("Status", selection: $selectedStatus) {
                            Text("Alpha").tag(SDKVersion.SDKVersionStatus.alpha)
                            Text("Beta").tag(SDKVersion.SDKVersionStatus.beta)
                            Text("Stable").tag(SDKVersion.SDKVersionStatus.stable)
                        }
                    }
                    Section("Release Notes") {
                        TextEditor(text: $releaseNotes)
                            .frame(minHeight: 100)
                    }
                }
                .navigationTitle("New Version")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAddVersion = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Register") { saveVersion() }
                            .disabled(versionString.isEmpty)
                    }
                }
            }
        }
    }

    private func statusBadge(_ status: SDKVersion.SDKVersionStatus) -> some View {
        let color: Color = {
            switch status {
            case .alpha: return .red
            case .beta: return .orange
            case .stable: return .green
            case .deprecated: return .gray
            }
        }()

        return Text(status.rawValue.uppercased())
            .font(.system(size: 8, weight: .bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.1))
            .foregroundStyle(color)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(color.opacity(0.2), lineWidth: 1))
    }

    private func saveVersion() {
        let newVersion = SDKVersion(
            sdkID: UUID(), // Simplified for now
            versionString: versionString,
            releaseNotes: releaseNotes,
            status: selectedStatus
        )
        var updated = store.sdkVersions
        updated.append(newVersion)
        store.saveSDKVersions(updated)

        versionString = ""
        releaseNotes = ""
        showingAddVersion = false
    }

    private func deleteVersion(at offsets: IndexSet) {
        var updated = store.sdkVersions
        updated.remove(atOffsets: offsets)
        store.saveSDKVersions(updated)
    }
}
