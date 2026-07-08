import SwiftUI

struct AppLockView: View {
    @StateObject private var manager = AppLockManager.shared
    @StateObject private var authManager = ScreenTimeAuthorizationManager.shared
    @State private var showingAddProfile = false
    @State private var newProfileName = ""

    var body: some View {
        List {
            Section(header: Text("Permissions"), footer: Text(authManager.state == .unavailable ? "App Lock is not available on Mac Catalyst." : "App Lock requires Screen Time permissions to function correctly.")) {
                if authManager.state == .unavailable {
                    Label("Unavailable on Mac Catalyst", systemImage: "xmark.octagon.fill")
                        .foregroundColor(.secondary)
                } else if authManager.isAuthorized {
                    Label("Authorized", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Button(action: {
                        Task {
                            do {
                                try await authManager.requestAuthorization()
                            } catch {
                                print("Authorization failed: \(error)")
                            }
                        }
                    }) {
                        Label("Request Authorization", systemImage: "shield.fill")
                    }
                }
            }

            Section(header: Text("App Lock Profiles")) {
                if manager.profiles.isEmpty {
                    Text("No profiles created")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(manager.profiles) { profile in
                        NavigationLink(destination: AppLockSessionView(profile: profile)) {
                            HStack {
                                Label(profile.name, systemImage: "app.badge.key")
                                Spacer()
                                if profile.isActive {
                                    Text("Active")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            manager.deleteProfile(id: manager.profiles[index].id)
                        }
                    }
                }

                #if !targetEnvironment(macCatalyst)
                Button(action: { showingAddProfile = true }) {
                    Label("Add Profile", systemImage: "plus.circle")
                }
                #endif
            }
        }
        .navigationTitle("App Lock System")
        .alert("New Profile", isPresented: $showingAddProfile) {
            TextField("Profile Name", text: $newProfileName)
            Button("Cancel", role: .cancel) { newProfileName = "" }
            Button("Create") {
                if !newProfileName.isEmpty {
                    manager.createProfile(name: newProfileName)
                    newProfileName = ""
                }
            }
        }
    }
}
