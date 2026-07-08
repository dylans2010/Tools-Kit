import SwiftUI
#if !targetEnvironment(macCatalyst)
import FamilyControls
#endif

struct AppSelectionView: View {
    @ObservedObject var manager = AppLockManager.shared
    @Binding var profile: AppLockProfile
    @State private var isPickerPresented = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        List {
            Section(header: Text("Profile Name")) {
                TextField("Name", text: $profile.name)
                    .onChange(of: profile.name) { _, _ in
                        manager.updateProfile(profile)
                    }
            }

            Section(header: Text("Selected Apps")) {
                #if targetEnvironment(macCatalyst)
                Text("App selection is unavailable on Mac Catalyst")
                    .foregroundColor(.secondary)
                    .italic()
                #else
                if profile.selection.applicationTokens.isEmpty && profile.selection.categoryTokens.isEmpty {
                    Text("No apps selected")
                        .foregroundColor(.secondary)
                } else {
                    Text("\(profile.selection.applicationTokens.count) apps, \(profile.selection.categoryTokens.count) categories selected")
                }

                Button(action: { isPickerPresented = true }) {
                    Label("Choose Apps & Categories", systemImage: "app.badge.plus")
                }
                #endif
            }
        }
        .navigationTitle("Edit Profile")
        .conditionalFamilyActivityPicker(isPresented: $isPickerPresented, selection: $profile.selection)
        .onChange(of: profile.selection) { _, _ in
            manager.updateProfile(profile)
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

extension View {
    @ViewBuilder
    func conditionalFamilyActivityPicker(isPresented: Binding<Bool>, selection: Binding<FamilyActivitySelection>) -> some View {
        #if targetEnvironment(macCatalyst)
        self
        #else
        self.familyActivityPicker(isPresented: isPresented, selection: selection)
        #endif
    }
}
