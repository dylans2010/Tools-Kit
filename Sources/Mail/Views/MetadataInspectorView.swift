import SwiftUI

struct MetadataInspectorView: View {
    let email: EmailMessage

    var body: some View {
        NavigationStack {
            List {
                Section("Message") {
                    row(title: "Subject", value: email.subject)
                    row(title: "From", value: email.sender)
                    row(title: "Date", value: email.date.formatted(date: .long, time: .shortened))
                    row(title: "UID", value: String(email.uid))
                    row(title: "Read", value: email.isRead ? "Yes" : "No")
                }

                if !email.attachments.isEmpty {
                    Section("Attachments (\(email.attachments.count))") {
                        ForEach(email.attachments) { attachment in
                            row(title: attachment.filename, value: attachment.mimeType)
                        }
                    }
                }
            }
            .navigationTitle("Message Details")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func row(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}
