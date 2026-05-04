import SwiftUI

struct SecurityPermissionCenterView: View {
    @State private var cameraPermission = true
    @State private var micPermission = true
    @State private var photoLibraryPermission = false
    @State private var locationPermission = true

    var body: some View {
        List {
            Section(header: Text("System Permissions"), footer: Text("Revoking permissions here will disable corresponding features within ToolsKit.")) {
                Toggle(isOn: $cameraPermission) {
                    Label("Camera", systemImage: "camera.fill")
                }
                Toggle(isOn: $micPermission) {
                    Label("Microphone", systemImage: "mic.fill")
                }
                Toggle(isOn: $photoLibraryPermission) {
                    Label("Photo Library", systemImage: "photo.on.rectangle.angled")
                }
                Toggle(isOn: $locationPermission) {
                    Label("Location", systemImage: "location.fill")
                }
            }

            Section(header: Text("Usage by Module")) {
                NavigationLink("GitHub Workspace") {
                    Text("GitHub Permissions")
                }
                NavigationLink("Media Editing") {
                    Text("Media Editing Permissions")
                }
                NavigationLink("Messages Extension") {
                    Text("Messages Permissions")
                }
            }

            Section {
                Button("Revoke All Permissions", role: .destructive) {
                    // Revoke logic
                }
            }
        }
        .navigationTitle("Permission Center")
    }
}
