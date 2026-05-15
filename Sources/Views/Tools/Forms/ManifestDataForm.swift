import SwiftUI

struct ManifestDataForm: View {
    let manifest: FormManifest

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            row(label: "Created By", value: manifest.createdBy)
            Divider().padding(.leading, 120)
            row(label: "Created", value: manifest.createdAt.formatted(date: .abbreviated, time: .shortened))
            Divider().padding(.leading, 120)
            row(label: "Last Edited", value: manifest.lastEditedAt.formatted(date: .abbreviated, time: .shortened))
            Divider().padding(.leading, 120)
            row(label: "Form Version", value: manifest.formVersion)
            Divider().padding(.leading, 120)
            row(label: "Schema", value: manifest.manifestSchemaVersion)
            Divider().padding(.leading, 120)
            row(label: "App Version", value: "\(manifest.appVersion) (\(manifest.buildNumber))")
            Divider().padding(.leading, 120)
            row(label: "Bundle ID", value: manifest.bundleIdentifier)
            Divider().padding(.leading, 120)
            row(label: "Platform", value: manifest.platform)
            Divider().padding(.leading, 120)
            row(label: "Locale", value: manifest.localeIdentifier)
            Divider().padding(.leading, 120)
            row(label: "Time Zone", value: manifest.timeZoneIdentifier)
            Divider().padding(.leading, 120)
            row(label: "Questions", value: "\(manifest.questionCount) (\(manifest.requiredQuestionCount) required)")
            Divider().padding(.leading, 120)
            row(label: "Attachments", value: manifest.supportsAttachments ? "Yes" : "No")
            if let templateName = manifest.templateName, !templateName.isEmpty {
                Divider().padding(.leading, 120)
                row(label: "Template", value: templateName)
            }
            if !manifest.privacyNote.isEmpty {
                Divider().padding(.leading, 120)
                row(label: "Privacy", value: manifest.privacyNote)
            }
            if !manifest.tags.isEmpty {
                Divider().padding(.leading, 120)
                row(label: "Tags", value: manifest.tags.joined(separator: ", "))
            }
        }
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
    }

    private func row(label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 108, alignment: .leading)
            Text(value)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(2)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
