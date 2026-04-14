import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct EmailComposingView: View {
    @Environment(\.dismiss) var dismiss
    let account: MailAccount
    var replyTo: MailMessage? = nil

    @State private var toRecipients: [String] = []
    @State private var newRecipient = ""
    @State private var subject = ""
    @State private var messageBody = ""
    @State private var isSending = false
    @State private var showingAISuggestions = false

    @State private var showingDocumentPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Recipients field
                HStack {
                    Text("To:")
                        .foregroundColor(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(toRecipients, id: \.self) { recipient in
                                Text(recipient)
                                    .font(.subheadline)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Color.blue.opacity(0.1)))
                                    .foregroundColor(.blue)
                                    .onTapGesture {
                                        toRecipients.removeAll { $0 == recipient }
                                    }
                            }

                            TextField("", text: $newRecipient)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .keyboardType(.emailAddress)
                                .onSubmit {
                                    if !newRecipient.isEmpty {
                                        toRecipients.append(newRecipient)
                                        newRecipient = ""
                                    }
                                }
                                .frame(minWidth: 100)
                        }
                    }
                }
                .padding()

                Divider().padding(.horizontal)

                // Subject field
                TextField("Subject", text: $subject)
                    .font(.headline)
                    .padding()

                Divider().padding(.horizontal)

                // Body field
                ZStack(alignment: .topLeading) {
                    if messageBody.isEmpty {
                        Text("Write your message here...")
                            .foregroundColor(.secondary)
                            .padding(.top, 16)
                            .padding(.leading, 20)
                    }

                    TextEditor(text: $messageBody)
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }

                Spacer()
            }
            .navigationTitle(replyTo == nil ? "New Message" : "Reply")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { showingAISuggestions = true }) {
                            Image(systemName: "sparkles")
                                .foregroundStyle(.purple)
                        }

                        Button(action: send) {
                            if isSending {
                                ProgressView()
                            } else {
                                Image(systemName: "paperplane.fill")
                            }
                        }
                        .disabled(toRecipients.isEmpty && newRecipient.isEmpty || subject.isEmpty || isSending)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                FormattingToolbar(
                    onBold: { wrap("**") },
                    onItalic: { wrap("_") },
                    onUnderline: { wrap("__") },
                    onBulletList: { insert("\n• ") },
                    onNumberList: { insert("\n1. ") },
                    onLink: { insert("[text](url)") },
                    onAttach: { showingDocumentPicker = true },
                    onImage: { /* Handled by PhotosPicker */ }
                )
                .background(Material.bar)
                .overlay(
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Color.clear.frame(width: 44, height: 44)
                    }
                    .offset(x: 120) // Adjust based on button positions
                )
            }
            .onAppear {
                if let reply = replyTo {
                    toRecipients = [reply.from]
                    subject = "Re: \(reply.subject)"
                    messageBody = "\n\n--- On \(reply.date.description) \(reply.from) wrote: ---\n\(reply.body)"
                }
            }
            .sheet(isPresented: $showingAISuggestions) {
                AIWritingAssistantSheet(replyTo: replyTo, currentBody: messageBody) { suggestion in
                    messageBody = suggestion
                }
            }
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentPickerWrapper()
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func insert(_ text: String) {
        messageBody += text
    }

    private func wrap(_ marker: String) {
        messageBody += "\(marker)text\(marker)"
    }

    private func send() {
        var recipients = toRecipients
        if !newRecipient.isEmpty { recipients.append(newRecipient) }

        isSending = true
        Task {
            do {
                let provider = iCloudMailProvider(account: account)
                let message = MailMessage(
                    id: UUID().uuidString,
                    threadId: replyTo?.threadId ?? UUID().uuidString,
                    from: account.email,
                    to: recipients,
                    cc: [],
                    bcc: [],
                    subject: subject,
                    body: messageBody,
                    htmlBody: nil,
                    date: Date(),
                    isRead: true,
                    isStarred: false,
                    attachments: []
                )
                try await provider.sendMessage(message)
                await MainActor.run {
                    isSending = false
                    dismiss()
                }
            } catch {
                print("Failed to send email: \(error)")
                await MainActor.run { isSending = false }
            }
        }
    }
}

// MARK: - Formatting Toolbar

struct FormattingToolbar: View {
    var onBold: () -> Void
    var onItalic: () -> Void
    var onUnderline: () -> Void
    var onBulletList: () -> Void
    var onNumberList: () -> Void
    var onLink: () -> Void
    var onAttach: () -> Void
    var onImage: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ToolbarButton(icon: "bold", action: onBold)
                ToolbarButton(icon: "italic", action: onItalic)
                ToolbarButton(icon: "underline", action: onUnderline)
                ToolbarButton(icon: "list.bullet", action: onBulletList)
                ToolbarButton(icon: "list.number", action: onNumberList)
                ToolbarButton(icon: "link", action: onLink)
                ToolbarButton(icon: "paperclip", action: onAttach)
                ToolbarButton(icon: "photo.on.rectangle", action: onImage)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
    }
}

struct ToolbarButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.primary)
        }
    }
}

// MARK: - AI Writing Assistant Sheet

struct AIWritingAssistantSheet: View {
    let replyTo: MailMessage?
    let currentBody: String
    let onApply: (String) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var aiContext = ""
    @State private var selectedTone = "Professional"
    @State private var isGenerating = false
    @State private var result: String? = nil
    @State private var shimmerOffset: CGFloat = -1

    let tones = ["Professional", "Casual", "Persuasive", "Friendly"]

    var body: some View {
        VStack(spacing: 20) {
            Text("AI Writing Assistant")
                .font(.headline)
                .foregroundColor(.white)

            TextField("What do you want to say?", text: $aiContext)
                .textFieldStyle(.plain)
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.2)))
                .foregroundColor(.white)

            HStack {
                ForEach(tones, id: \.self) { tone in
                    Button(action: { selectedTone = tone }) {
                        Text(tone)
                            .font(.caption.bold())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedTone == tone ? Color.white : Color.white.opacity(0.2))
                            .foregroundColor(selectedTone == tone ? .purple : .white)
                            .clipShape(Capsule())
                    }
                }
            }

            if isGenerating {
                shimmerView
            } else if let aiResult = result {
                VStack(spacing: 12) {
                    ScrollView {
                        Text(aiResult)
                            .padding()
                            .font(.callout)
                            .foregroundColor(.primary)
                    }
                    .frame(maxHeight: 200)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)

                    HStack {
                        Button("Copy") {
                            UIPasteboard.general.string = aiResult
                        }
                        .buttonStyle(.bordered)

                        Button("Insert") {
                            onApply(aiResult)
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            } else {
                Button(action: generate) {
                    Text("Generate Draft")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.purple)
                        .cornerRadius(12)
                }
            }

            Spacer()
        }
        .padding()
        .presentationBackground {
            LinearGradient(colors: [.purple.opacity(0.88), .blue.opacity(0.92)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        .presentationDetents([.medium])
    }

    private var shimmerView: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white.opacity(0.1))
            .frame(height: 100)
            .overlay(
                GeometryReader { geo in
                    Rectangle()
                        .fill(
                            LinearGradient(colors: [.clear, .white.opacity(0.3), .clear], startPoint: .leading, endPoint: .trailing)
                        )
                        .offset(x: shimmerOffset * geo.size.width)
                        .onAppear {
                            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                                shimmerOffset = 1
                            }
                        }
                }
            )
            .clipped()
    }

    private func generate() {
        isGenerating = true
        Task {
            do {
                let draft: String
                if let reply = replyTo {
                    draft = try await MailAIService.shared.generateReply(for: reply, context: aiContext)
                } else {
                    draft = try await MailAIService.shared.improveDraft(currentBody.isEmpty ? aiContext : currentBody, tone: selectedTone.lowercased())
                }
                await MainActor.run {
                    result = draft
                    isGenerating = false
                }
            } catch {
                await MainActor.run { isGenerating = false }
            }
        }
    }
}

// MARK: - Document Picker Wrapper

struct DocumentPickerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.data, .content])
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
}
