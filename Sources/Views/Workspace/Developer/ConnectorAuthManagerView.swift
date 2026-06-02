import SwiftUI

struct ConnectorAuthManagerView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared
    @State private var showingAdd = false
    @State private var name = ""
    @State private var type = "Bearer"
    @State private var identifier = ""

    var body: some View {
        List {
            Section("Credential Registry") {
                if store.authProfiles.isEmpty {
                    Text("No credentials saved.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.authProfiles) { profile in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(profile.name).font(.subheadline.bold())
                                Text("\(profile.type) • \(profile.identifier)").font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "lock.shield.fill")
                                .foregroundStyle(.green)
                        }
                    }
                    .onDelete(perform: deleteProfile)
                }
            }

            Section {
                Button(action: { showingAdd = true }) {
                    Label("Add Auth Profile", systemImage: "key.fill")
                }
            }
        }
        .navigationTitle("Connector Auth")
        .sheet(isPresented: $showingAdd) {
            NavigationStack {
                Form {
                    Section("Identity") {
                        TextField("Profile Name", text: $name)
                        Picker("Auth Type", selection: $type) {
                            Text("Bearer Token").tag("Bearer")
                            Text("API Key").tag("APIKey")
                            Text("OAuth2").tag("OAuth2")
                        }
                        TextField("Identifier (e.g. key ID)", text: $identifier)
                    }
                }
                .navigationTitle("New Profile")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAdd = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { saveProfile() }
                            .disabled(name.isEmpty)
                    }
                }
            }
        }
    }

    private func saveProfile() {
        let new = AuthProfile(name: name, type: type, identifier: identifier)
        var updated = store.authProfiles
        updated.append(new)
        store.saveAuthProfiles(updated)
        name = ""
        identifier = ""
        showingAdd = false
    }

    private func deleteProfile(at offsets: IndexSet) {
        var updated = store.authProfiles
        updated.remove(atOffsets: offsets)
        store.saveAuthProfiles(updated)
    }
}
