import SwiftUI

struct FileManagementActionsSectionView: View {
    @ObservedObject var backend: FileManagementBackend
    @Binding var showingImporter: Bool
    @Binding var showingCreateFolder: Bool
    @Binding var showingCreateFile: Bool
    @Binding var showingTemplates: Bool

    var body: some View {
        ToolInputSection("Actions") {
            VStack(spacing: 0) {
                actionRow(icon: "square.and.arrow.down", label: "Import Files", color: .blue) {
                    showingImporter = true
                }
                Divider().padding(.leading, 52)
                actionRow(icon: "folder.badge.plus", label: "New Folder", color: .orange) {
                    showingCreateFolder = true
                }
                Divider().padding(.leading, 52)
                actionRow(icon: "doc.badge.plus", label: "New File", color: .green) {
                    showingCreateFile = true
                }
                Divider().padding(.leading, 52)
                actionRow(icon: "doc.on.doc", label: "From Template", color: .purple) {
                    showingTemplates = true
                }
                Divider().padding(.leading, 52)
                Button {
                    Task { await backend.summarizeSelectedFile() }
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "sparkles")
                            .font(.body)
                            .foregroundColor(.white)
                            .frame(width: 30, height: 30)
                            .background(Color.indigo)
                            .cornerRadius(8)
                        Text("AI Summary")
                            .font(.body)
                            .foregroundColor(.primary)
                        Spacer()
                        if backend.isSummarizing {
                            ProgressView()
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
                .disabled(backend.selectedItem == nil || backend.selectedItem?.isDirectory == true)
                .buttonStyle(.plain)
            }
        }
    }

    private func actionRow(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(color)
                    .cornerRadius(8)
                Text(label)
                    .font(.body)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }
}

