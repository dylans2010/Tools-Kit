import SwiftUI

struct AFMSettingsView: View {
    @AppStorage("afm_use_cloud_fallback") private var useCloudFallback = false
    @AppStorage("afm_priority") private var afmPriority = "Performance"

    var body: some View {
        List {
            Section(header: Text("Model Configuration")) {
                Toggle("Cloud Fallback (Private Cloud Compute)", isOn: $useCloudFallback)

                Picker("Optimization Priority", selection: $afmPriority) {
                    Text("Performance").tag("Performance")
                    Text("Battery Life").tag("Battery")
                    Text("Accuracy").tag("Accuracy")
                }
            }

            Section(header: Text("Storage")) {
                Button("Sync Model Assets") {
                    Task {
                        AFMModelManager.shared.refreshModels()
                    }
                }

                HStack {
                    Text("Total Model Size")
                    Spacer()
                    Text("3.1 GB")
                        .foregroundColor(.secondary)
                }
            }

            Section(header: Text("Privacy")) {
                Text("All processing is performed on-device or via Private Cloud Compute. No data is stored or shared with Apple.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("AFM Settings")
    }
}
