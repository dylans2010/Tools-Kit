import SwiftUI

/// Handles file attachments and metadata for Collaboration.
struct CollaborationFileSharingLayer {
    static func uploadFile(url: URL, channelID: UUID) async throws -> CollaborationAttachment {
        // Mock upload logic
        let filename = url.lastPathComponent
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let size = attributes[.size] as? Int64 ?? 0

        return CollaborationAttachment(
            id: UUID(),
            name: filename,
            type: url.pathExtension,
            size: size,
            url: url.absoluteString,
            metadata: [
                "uploadedAt": ISO8601DateFormatter().string(from: Date()),
                "contentType": "application/octet-stream"
            ]
        )
    }
}

struct AttachmentPreviewView: View {
    let attachment: CollaborationAttachment

    var body: some View {
        HStack(spacing: 10) {
            fileIcon(for: attachment.type)
                .font(.title2)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text(attachment.name)
                    .font(.caption.bold())
                    .lineLimit(1)
                Text(ByteCountFormatter.string(fromByteCount: attachment.size, countStyle: .file))
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button { /* Download/Preview */ } label: {
                Image(systemName: "arrow.down.doc")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }

    private func fileIcon(for ext: String) -> Image {
        switch ext.lowercased() {
        case "pdf": return Image(systemName: "doc.richtext.fill")
        case "png", "jpg", "jpeg": return Image(systemName: "photo.fill")
        case "swift", "js", "py": return Image(systemName: "doc.text.fill")
        default: return Image(systemName: "doc.fill")
        }
    }
}
