import SwiftUI

struct SecurityAppLockRulesView: View {
    @State private var lockGitHub = false
    @State private var lockMessages = false
    @State private var lockKeyboardAI = false
    @State private var lockEditing = false

    var body: some View {
        List {
            Section(header: Text("Module Locking"), footer: Text("Locked modules will require re-authentication even if the main vault is open.")) {
                Toggle(isOn: $lockGitHub) {
                    Label("GitHub Workspace", systemImage: "terminal.fill")
                }
                Toggle(isOn: $lockMessages) {
                    Label("Messages Extension", systemImage: "message.fill")
                }
                Toggle(isOn: $lockKeyboardAI) {
                    Label("Keyboard AI Features", systemImage: "keyboard")
                }
                Toggle(isOn: $lockEditing) {
                    Label("Media Editing", systemImage: "photo.stack.fill")
                }
            }

            Section(header: Text("Conditional Rules")) {
                NavigationLink("Geofenced Access") {
                    Text("Geofencing Settings")
                }
                NavigationLink("Time-based Restrictions") {
                    Text("Schedule Settings")
                }
            }
        }
        .navigationTitle("App Lock Rules")
    }
}
