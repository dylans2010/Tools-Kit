import SwiftUI

struct Diag_MetalCapabilityView: View {
    var body: some View {
        List {
            Section("Metal GPU Details") {
                LabeledContent("GPU Family", value: "Apple Family 9")
                LabeledContent("Max Buffer Size", value: "4 GB")
                LabeledContent("Max Texture Size", value: "16384 x 16384")
                LabeledContent("RT Core Support", value: "Yes (Hardware)")
            }

            Section("Feature Support") {
                FeatureRow(name: "Mesh Shaders", supported: true)
                FeatureRow(name: "Ray Tracing", supported: true)
                FeatureRow(name: "Variable Rate Shading", supported: true)
                FeatureRow(name: "Function Pointers", supported: true)
            }
        }
        .navigationTitle("Metal Capabilities")
    }
}

struct FeatureRow: View {
    let name: String
    let supported: Bool
    var body: some View {
        HStack {
            Text(name)
            Spacer()
            Image(systemName: supported ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(supported ? .green : .red)
        }
    }
}
