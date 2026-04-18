import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

// MARK: - Main Composer View

struct EmailComposingView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) var dismiss
    let account: MailAccount
    var replyTo: MailMessage? = nil

    // Recipients
    @State private var toRecipients: [String] = []
    @State private var newRecipient = ""
    @State private var subject = ""
    @State private var messageBody = ""
    @State private var draftAttachments: [MailMessage.MailAttachment] = []

    // State
    @State private var isSending = false
    @State private var showingAIPanel = false
    @State private var showingAttachmentPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var sendError: String?
    @FocusState private var bodyFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: colorScheme == .dark
                        ? [Color(red: 0.08, green: 0.11, blue: 0.16), Color(red: 0.06, green: 0.08, blue: 0.13)]
                        : [Color(red: 0.97, green: 0.99, blue: 1.0), Color(red: 0.90, green: 0.95, blue: 1.0)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        composerHero
                        recipientsCard
                        subjectCard
                        bodyCard
                        attachmentsCard
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle(replyTo == nil ? "New Message" : "Reply")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .safeAreaInset(edge: .bottom) { bottomToolbar }
            .onAppear(perform: prefillReply)
            .onChange(of: selectedPhotoItem) { newItem in
                guard let newItem else { return }
                Task { await importPhoto(newItem) }
            }
            .sheet(isPresented: $showingAIPanel) {
                DraftingEmailsView(currentBody: messageBody) { result in
                    let trimmedRecipient = result.recipient.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmedRecipient.isEmpty, !toRecipients.contains(trimmedRecipient) {
                        toRecipients.append(trimmedRecipient)
                    }

                    let trimmedSubject = result.subject.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmedSubject.isEmpty {
                        subject = trimmedSubject
                    }

                    if !result.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        messageBody = result.body
                    }
                }
            }
            .sheet(isPresented: $showingAttachmentPicker) {
                FileImporterRepresentableView(
                    allowedContentTypes: [.data, .image, .pdf, .text],
                    allowsMultipleSelection: true
                ) { urls in
                    handleImportedAttachments(urls)
                    showingAttachmentPicker = false
                }
            }
            .alert("Send Failed", isPresented: Binding(
                get: { sendError != nil },
                set: { if !$0 { sendError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(sendError ?? "")
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Recipients

    private var composerHero: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(replyTo == nil ? "Compose Mail" : "Reply in Style")
                        .font(.title2.bold())
                    Text("Draft faster with polished formatting, attachments, and AI polish tools.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: replyTo == nil ? "square.and.pencil" : "arrowshape.turn.up.left")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }

            HStack(spacing: 10) {
                Label("Selected model", systemImage: "brain.head.profile")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.75), in: Capsule())
                Text("Uses the AI Chat settings model")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(LinearGradient(colors: [.blue.opacity(0.35), .cyan.opacity(0.25)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                )
        )
    }

    private var recipientsCard: some View {
        editorCard(title: "Recipients", systemImage: "person.2.fill") {
            HStack(alignment: .top, spacing: 10) {
                Text("To")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                    .padding(.top, 12)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(toRecipients, id: \.self) { recipient in
                            recipientChip(recipient)
                        }
                        TextField("Add recipient", text: $newRecipient)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .keyboardType(.emailAddress)
                            .onSubmit { commitRecipient() }
                            .frame(minWidth: 160)
                            .padding(.vertical, 10)
                    }
                }
            }
        }
    }

    // MARK: - Subject

    private var subjectCard: some View {
        editorCard(title: "Subject", systemImage: "textformat.size") {
            TextField("Write a subject", text: $subject)
                .font(.headline)
                .textInputAutocapitalization(.sentences)
                .disableAutocorrection(true)
        }
    }

    // MARK: - Body Editor

    private var bodyCard: some View {
        editorCard(title: "Message", systemImage: "text.alignleft") {
            ZStack(alignment: .topLeading) {
                if messageBody.isEmpty && !bodyFocused {
                    Text("Write your message…")
                        .foregroundColor(Color(.placeholderText))
                        .padding(.top, 14)
                        .padding(.leading, 18)
                }
                TextEditor(text: $messageBody)
                    .focused($bodyFocused)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .frame(minHeight: 260)
            }
        }
    }

    private var attachmentsCard: some View {
        Group {
            if !draftAttachments.isEmpty {
                editorCard(title: "Attachments", systemImage: "paperclip") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(draftAttachments) { attachment in
                                attachmentChip(attachment)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
    }

    private func editorCard<Content: View>(title: String, systemImage: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .foregroundStyle(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                Text(title)
                    .font(.headline)
                Spacer()
            }

            content()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.10) : Color.blue.opacity(0.14), lineWidth: 1)
                )
                .shadow(color: colorScheme == .dark ? Color.black.opacity(0.35) : Color.blue.opacity(0.08), radius: 18, x: 0, y: 8)
        )
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Cancel") { dismiss() }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 16) {
                // AI button
                Button { showingAIPanel = true } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                        Text("AI")
                            .font(.subheadline.bold())
                    }
                    .foregroundStyle(
                        LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing)
                    )
                }

                // Send button
                Button(action: send) {
                    if isSending {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "paperplane.fill")
                    }
                }
                .disabled(cannotSend)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    LinearGradient(colors: cannotSend ? [Color.gray.opacity(0.45), Color.gray.opacity(0.35)] : [.blue, .cyan], startPoint: .leading, endPoint: .trailing),
                    in: Capsule()
                )
                .foregroundColor(.white)
            }
        }
    }

    private var cannotSend: Bool {
        (toRecipients.isEmpty && newRecipient.isEmpty) || subject.isEmpty || isSending
    }

    // MARK: - Bottom Formatting Toolbar

    private var bottomToolbar: some View {
        VStack(spacing: 0) {
            Divider()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ComposeToolbarButton(icon: "bold",              label: "Bold")       { wrap("**") }
                    ComposeToolbarButton(icon: "italic",            label: "Italic")     { wrap("_") }
                    ComposeToolbarButton(icon: "underline",         label: "Underline")  { wrap("__") }
                    Divider().frame(height: 24)
                    ComposeToolbarButton(icon: "text.quote",        label: "Quote")      { insert("\n> ") }
                    ComposeToolbarButton(icon: "list.bullet",       label: "Bullets")    { insert("\n• ") }
                    ComposeToolbarButton(icon: "list.number",       label: "Numbers")    { insert("\n1. ") }
                    ComposeToolbarButton(icon: "checklist",         label: "Checklist")  { insert("\n- [ ] ") }
                    Divider().frame(height: 24)
                    ComposeToolbarButton(icon: "link",              label: "Link")       { insert("[text](url)") }
                    ComposeToolbarButton(icon: "paperclip",         label: "Attach")     { showingAttachmentPicker = true }
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label("Photo", systemImage: "photo.on.rectangle")
                            .labelStyle(.iconOnly)
                            .font(.system(size: 19))
                            .foregroundColor(.primary)
                            .frame(width: 40, height: 40)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
        }
        .background(Material.bar)
    }

    // MARK: - Helpers

    private func prefillReply() {
        guard let reply = replyTo else { return }
        toRecipients = [reply.from]
        subject = "Re: \(reply.subject)"
        let dateString = DateFormatter.localizedString(from: reply.date, dateStyle: .medium, timeStyle: .short)
        let quotedBody = MailContentRenderer.render(htmlBody: reply.htmlBody, plainBody: reply.body).plainBody ?? reply.body
        messageBody = "\n\n--- On \(dateString), \(reply.from) wrote: ---\n\(quotedBody)"
    }

    private func commitRecipient() {
        let trimmed = newRecipient.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        toRecipients.append(trimmed)
        newRecipient = ""
    }

    private func insert(_ text: String) {
        messageBody += text
    }

    private func wrap(_ marker: String) {
        messageBody += "\(marker)text\(marker)"
    }

    private func recipientChip(_ recipient: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "person.crop.circle.fill")
                .font(.caption)

            Text(recipient)
                .font(.caption.weight(.semibold))
                .lineLimit(1)

            Button {
                toRecipients.removeAll { $0 == recipient }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.blue.opacity(0.10), in: Capsule())
        .foregroundColor(.blue)
    }

    private func attachmentChip(_ attachment: MailMessage.MailAttachment) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "doc.fill")
                .font(.caption)
            Text(attachment.fileName)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
            Button {
                draftAttachments.removeAll { $0.id == attachment.id }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.blue.opacity(0.10), in: Capsule())
        .foregroundColor(.blue)
    }

    private func handleImportedAttachments(_ urls: [URL]) {
        for url in urls {
            let accessed = url.startAccessingSecurityScopedResource()
            defer {
                if accessed { url.stopAccessingSecurityScopedResource() }
            }

            guard let data = try? Data(contentsOf: url) else { continue }
            let mimeType = UTType(filenameExtension: url.pathExtension)?.preferredMIMEType
                ?? UTType(filenameExtension: url.pathExtension)?.identifier
                ?? "application/octet-stream"

            let attachment = MailMessage.MailAttachment(
                id: UUID().uuidString,
                fileName: url.lastPathComponent,
                contentType: mimeType,
                size: Int64(data.count)
            )
            draftAttachments.append(attachment)
        }
    }

    private func importPhoto(_ item: PhotosPickerItem) async {
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                let attachment = MailMessage.MailAttachment(
                    id: UUID().uuidString,
                    fileName: "Photo-\(draftAttachments.count + 1).jpg",
                    contentType: "image/jpeg",
                    size: Int64(data.count)
                )
                await MainActor.run {
                    draftAttachments.append(attachment)
                    selectedPhotoItem = nil
                }
            } else {
                await MainActor.run {
                    selectedPhotoItem = nil
                }
            }
        } catch {
            await MainActor.run {
                sendError = error.localizedDescription
                selectedPhotoItem = nil
            }
        }
    }

    private func send() {
        var recipients = toRecipients
        if !newRecipient.trimmingCharacters(in: .whitespaces).isEmpty {
            recipients.append(newRecipient.trimmingCharacters(in: .whitespaces))
        }
        guard !recipients.isEmpty else { return }

        isSending = true
        Task {
            do {
                let provider: MailProviderProtocol
                switch account.provider {
                case .icloud, .imap, .proton, .yahoo, .outlook:
                    provider = iCloudMailProvider(account: account)
                case .gmail:
                    provider = GmailMailProvider(account: account)
                }
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
                    attachments: draftAttachments
                )
                try await provider.sendMessage(message)
                await MainActor.run {
                    isSending = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSending = false
                    sendError = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Compose Toolbar Button

private struct ComposeToolbarButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.primary)
                .frame(width: 40, height: 40)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(label)
    }
}
