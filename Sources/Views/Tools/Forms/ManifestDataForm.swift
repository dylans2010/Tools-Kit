import SwiftUI

struct ManifestDataForm: View {
    let manifest: FormManifest

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Created by: \(manifest.createdBy)")
            Text("Created at: \(manifest.createdAt.formatted(date: .abbreviated, time: .shortened))")
            Text("App version: \(manifest.appVersion)")
            Text("Privacy: \(manifest.privacyNote)")
        }
        .font(.caption)
        .foregroundColor(.secondary)
    }
}
