import SwiftUI

struct PrivacyManifestEditorView: View {
    @State private var apiUsageReasons: Set<String> = []
    @State private var dataCollectionTypes: Set<String> = []
    @State private var showingExport = false

    var body: some View {
        Form {
            Section("Required API Usage Reasons") {
                Text("Select reasons for using sensitive system APIs as required by platform privacy policies.")
                    .font(.caption).foregroundStyle(.secondary)

                ForEach(["User Defaults", "File Timestamp", "System Boot Time", "Disk Space"], id: \.self) { reason in
                    Toggle(reason, isOn: Binding(
                        get: { apiUsageReasons.contains(reason) },
                        set: { if $0 { apiUsageReasons.insert(reason) } else { apiUsageReasons.remove(reason) } }
                    ))
                }
            }

            Section("Data Collection") {
                Text("Declare what types of user data your app collects.")
                    .font(.caption).foregroundStyle(.secondary)

                ForEach(["Contact Info", "Health & Fitness", "Financial Info", "Location", "Identifiers"], id: \.self) { type in
                    Toggle(type, isOn: Binding(
                        get: { dataCollectionTypes.contains(type) },
                        set: { if $0 { dataCollectionTypes.insert(type) } else { dataCollectionTypes.remove(type) } }
                    ))
                }
            }

            Section {
                Button("Generate Privacy Manifest") {
                    showingExport = true
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Privacy Manifest")
        .alert("Manifest Generated", isPresented: $showingExport) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("PrivacyInfo.xcprivacy has been generated based on your selections.")
        }
    }
}
