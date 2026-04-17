import SwiftUI
import PhotosUI

struct AIMentorChatView: View {
    @StateObject private var manager = WorkoutsManager.shared
    @State private var inputText: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var isSending = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(manager.mentorMessages) { message in
                            messageBubble(message)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: manager.mentorMessages.count) { _ in
                    if let lastID = manager.mentorMessages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastID, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            HStack(alignment: .bottom, spacing: 8) {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Image(systemName: selectedImageData == nil ? "photo" : "photo.fill")
                        .font(.title3)
                }

                TextField("Ask your AI mentor", text: $inputText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)

                Button("Send") {
                    Task { await submitMessage() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
            }
            .padding()
        }
        .onChange(of: selectedPhotoItem) { _ in
            Task {
                selectedImageData = try? await selectedPhotoItem?.loadTransferable(type: Data.self)
            }
        }
    }

    private func messageBubble(_ message: MentorMessageModel) -> some View {
        VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
            Text(message.text)
                .padding(10)
                .background(message.role == .user ? Color.accentColor.opacity(0.2) : Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            if !message.insights.isEmpty && message.role == .assistant {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(message.insights, id: \.self) { insight in
                        Label(insight, systemImage: "lightbulb")
                            .font(.caption)
                    }
                }
            }
            if !message.recommendations.isEmpty && message.role == .assistant {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(message.recommendations, id: \.self) { rec in
                        Label(rec, systemImage: "checkmark.seal")
                            .font(.caption)
                    }
                }
            }
            if let imageHint = message.imageHint {
                Text(imageHint)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
    }

    @MainActor
    private func submitMessage() async {
        let prompt = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }
        isSending = true
        await manager.sendMentorMessage(prompt, imageData: selectedImageData)
        isSending = false
        inputText = ""
        selectedPhotoItem = nil
        selectedImageData = nil
    }
}
