import SwiftUI

struct ManifestDataForm: View {
    let manifest: FormManifest

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Created by: \(manifest.createdBy)")
            Text("Created at: \(manifest.createdAt.formatted(date: .abbreviated, time: .shortened))")
            Text("Last edited: \(manifest.lastEditedAt.formatted(date: .abbreviated, time: .shortened))")
            Text("Form version: \(manifest.formVersion)")
            Text("Manifest schema: \(manifest.manifestSchemaVersion)")
            Text("App version: \(manifest.appVersion) (\(manifest.buildNumber))")
            Text("Bundle ID: \(manifest.bundleIdentifier)")
            Text("Platform: \(manifest.platform)")
            Text("Locale: \(manifest.localeIdentifier)")
            Text("Time zone: \(manifest.timeZoneIdentifier)")
            Text("Question count: \(manifest.questionCount)")
            Text("Required questions: \(manifest.requiredQuestionCount)")
            Text("Supports attachments: \(manifest.supportsAttachments ? "Yes" : "No")")
            if let templateName = manifest.templateName, !templateName.isEmpty {
                Text("Template: \(templateName)")
            }
            Text("Privacy: \(manifest.privacyNote)")
            Text("Export: \(manifest.exportNote)")
            if !manifest.tags.isEmpty {
                Text("Tags: \(manifest.tags.joined(separator: ", "))")
            }
        }
        .font(.caption)
        .foregroundColor(.secondary)
    }
}
