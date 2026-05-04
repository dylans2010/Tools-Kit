import SwiftUI

struct SecureFolderItemPicker: View {
    @Environment(\.dismiss) var dismiss
    let onSelect: (SecureFolderItem) -> Void

    @StateObject private var vaultManager = VaultManager.shared
    @StateObject private var appLockManager = AppLockManager.shared
    // For files and notes, we'd normally use their respective managers

    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack {
                Picker("Item Type", selection: $selectedTab) {
                    Text("Passwords").tag(0)
                    Text("App Locks").tag(1)
                    Text("Others").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()

                List {
                    if selectedTab == 0 {
                        passwordSection
                    } else if selectedTab == 1 {
                        appLockSection
                    } else {
                        otherSection
                    }
                }
            }
            .navigationTitle("Add Item to Folder")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var passwordSection: some View {
        ForEach(vaultManager.items.filter { $0.category == .credentials }) { item in
            Button {
                onSelect(.password(id: item.id.uuidString))
                dismiss()
            } label: {
                Label(item.title, systemImage: "key.fill")
            }
        }
    }

    private var appLockSection: some View {
        Group {
            if appLockManager.profiles.isEmpty {
                Text("No App Lock profiles created yet.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(appLockManager.profiles) { profile in
                    Button {
                        onSelect(.app(id: profile.id))
                        dismiss()
                    } label: {
                        Label(profile.name, systemImage: "app.badge.key")
                    }
                }
            }
        }
    }

    private var otherSection: some View {
        Group {
            Text("Notes and Files can be added via their respective modules (simulated here for brevity).")
                .font(.caption)
                .foregroundColor(.secondary)

            Button("Add Sample Note") {
                onSelect(.note(id: UUID().uuidString))
                dismiss()
            }

            Button("Add Sample File") {
                onSelect(.file(id: UUID().uuidString))
                dismiss()
            }
        }
    }
}
