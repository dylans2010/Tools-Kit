
import SwiftUI

struct SDKWhiteLabelingView: View {
    @State private var companyName = ""
    @State private var appName = ""
    @State private var primaryColor: Color = .blue

    var body: some View {
        Form {
            Section("Branding") {
                TextField("Company Name", text: $companyName)
                TextField("App Name", text: $appName)
                ColorPicker("Primary Brand Color", selection: $primaryColor)
            }

            Section("Assets") {
                Button("Upload Custom Logo", systemImage: "photo.on.rectangle") { }
                Button("Upload Favicon", systemImage: "square.dashed") { }
            }

            Section {
                Text("Custom branding will be applied to the generated SDK artifacts and documentation.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("White-labeling")
    }
}
