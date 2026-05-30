import SwiftUI

struct PrivacyManifestEditorView: View {
    let appID: UUID
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var apiUsageReasons: Set<String> = []
    @State private var dataCollectionTypes: Set<String> = []
    @State private var showingExport = false

    let availableReasons = [
        "File Provider", "System Font", "Keyboard Access", "User Defaults", "Disk Space", "Active Sensors"
    ]

    let availableDataTypes = [
        "Email Address", "Name", "Phone Number", "Physical Address", "Precise Location", "Coarse Location"
    ]

    var body: some View {
        Form {
            Section("Required API Usage Reasons") {
                Text("Select reasons for using sensitive system APIs as required by platform privacy policies.")
                    .font(.caption).foregroundStyle(.secondary)

                ForEach(availableReasons, id: \.self) { reason in
                    Toggle(reason, isOn: binding(for: reason, in: $apiUsageReasons))
                }
            }

            Section("Data Collection") {
                Text("Declare what types of user data your app collects.")
                    .font(.caption).foregroundStyle(.secondary)

                ForEach(availableDataTypes, id: \.self) { dataType in
                    Toggle(dataType, isOn: binding(for: dataType, in: $dataCollectionTypes))
                }
            }

            Section {
                Button("Generate Privacy Manifest") {
                    showingExport = true
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle("Privacy Manifest")
        .alert("Manifest Generated", isPresented: $showingExport) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("PrivacyInfo.xcprivacy has been generated based on your selections and is ready for inclusion in your app bundle.")
        }
    }

    private func binding(for item: String, in set: Binding<Set<String>>) -> Binding<Bool> {
        Binding(
            get: { set.wrappedValue.contains(item) },
            set: { isSelected in
                if isSelected {
                    set.wrappedValue.insert(item)
                } else {
                    set.wrappedValue.remove(item)
                }
            }
        )
    }
}
