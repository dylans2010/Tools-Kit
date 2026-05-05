import SwiftUI

struct ConnectorVersioningView: View {
    @State var connector: ConnectorDefinition
    @StateObject private var manager = ConnectorManager.shared
    @State private var newVersion = ""
    @State private var releaseNotes = ""
    @State private var showingReleaseSheet = false

    var body: some View {
        List {
            Section("Active Version") {
                HStack {
                    Text("Current Version")
                    Spacer()
                    Text("v\(connector.version)")
                        .bold()
                        .foregroundColor(.blue)
                }
                HStack {
                    Text("Last Updated")
                    Spacer()
                    Text(connector.updatedAt.formatted(date: .abbreviated, time: .shortened))
                        .foregroundColor(.secondary)
                }
            }

            Section("Version History") {
                VStack(alignment: .leading, spacing: 12) {
                    historyRow(version: connector.version, date: connector.updatedAt, notes: "Current deployment")
                    historyRow(version: "0.9.0", date: connector.createdAt, notes: "Initial beta release")
                }
                .padding(.vertical, 8)
            }

            Section {
                Button {
                    newVersion = connector.version
                    showingReleaseSheet = true
                } label: {
                    Label("Create New Release", systemImage: "arrow.up.circle.fill")
                }
            }
        }
        .navigationTitle("Versioning")
        .sheet(isPresented: $showingReleaseSheet) {
            NavigationView {
                Form {
                    Section("Release Details") {
                        TextField("New Version (e.g. 1.1.0)", text: $newVersion)
                        VStack(alignment: .leading) {
                            Text("Release Notes").font(.caption).foregroundColor(.secondary)
                            TextEditor(text: $releaseNotes)
                                .frame(minHeight: 120)
                        }
                    }

                    Section {
                        Button("Publish Release") {
                            connector.version = newVersion
                            connector.updatedAt = Date()
                            manager.updateConnector(connector)
                            showingReleaseSheet = false
                        }
                        .disabled(newVersion == connector.version || newVersion.isEmpty)
                    }
                }
                .navigationTitle("New Release")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { showingReleaseSheet = false }
                    }
                }
            }
        }
    }

    private func historyRow(version: String, date: Date, notes: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
                Rectangle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 2)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("v\(version)")
                        .font(.subheadline.bold())
                    Spacer()
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
