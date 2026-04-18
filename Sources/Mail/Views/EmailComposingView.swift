import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct EmailComposingView: View {
    @Environment(\.dismiss) private var dismiss

    let account: MailAccount
    var replyTo: MailMessage? = nil

    @State private var toRecipients: [String] = []
    @State private var newRecipient = ""
    @State private var subject = ""
    @State private var messageBody = ""
    @State private var draftAttachments: [MailMessage.MailAttachment] = []

    @State private var isSending = false
    @State private var sendError: String?
    @State private var showingAIPanel = false
    @State private var showingAttachmentPicker = false
    @State private var showingAudioPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingTranslateSheet = false
    @State private var showingLinkSheet = false
    @State private var showingScheduleSheet = false
    @State private var showingDrawingSheet = false
    @State private var showingPreviewSheet = false

    @State private var scheduleDate: Date?
    @State private var pendingLinkText = ""
    @State private var pendingLinkURL = "https://"

    @FocusState private var bodyFocused: Bool
    
    private struct MarkdownFormatAction: Identifiable {
        let id = UUID()
        let title: String
        let icon: String
        let insertion: String
    }

    private let formattingActions: [MarkdownFormatAction] = [
        MarkdownFormatAction(title: "Bold", icon: "bold", insertion: "**bold text**"),
        MarkdownFormatAction(title: "Italic", icon: "italic", insertion: "_italic text_"),
        MarkdownFormatAction(title: "Strike", icon: "strikethrough", insertion: "~~strikethrough~~"),
        MarkdownFormatAction(title: "Inline Code", icon: "chevron.left.forwardslash.chevron.right", insertion: "`code`"),
        MarkdownFormatAction(title: "Heading", icon: "textformat.size", insertion: "## Heading"),
        MarkdownFormatAction(title: "Bullet List", icon: "list.bullet", insertion: "- First item\n- Second item"),
        MarkdownFormatAction(title: "Checklist", icon: "checklist", insertion: "- [ ] Todo item"),
        MarkdownFormatAction(title: "Numbered", icon: "list.number", insertion: "1. First\n2. Second"),
        MarkdownFormatAction(title: "Quote", icon: "text.quote", insertion: "> Quoted text"),
        MarkdownFormatAction(title: "Code Block", icon: "terminal", insertion: "```\ncode block\n```"),
        MarkdownFormatAction(title: "Table", icon: "tablecells", insertion: "| Column A | Column B |\n| --- | --- |\n| Value 1 | Value 2 |"),
        MarkdownFormatAction(title: "Divider", icon: "minus", insertion: "---")
    ]

    var body: some View {
        NavigationStack {
            Form {
                recipientsSection
                subjectSection
                bodySection
                toolsSection
                attachmentsSection
                scheduleSection
            }
            .navigationTitle(replyTo == nil ? "Compose" : "Reply")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if scheduleDate != nil {
                            Task { await handleScheduledOrImmediateSend() }
                        } else {
                            sendNow()
                        }
                    } label: {
                        if isSending {
                            ProgressView()
                        } else {
                            Label(scheduleDate != nil ? "Schedule" : "Send", systemImage: scheduleDate != nil ? "calendar.badge.clock" : "paperplane.fill")
                        }
                    }
                    .disabled(cannotSend)
                }
            }
            .onAppear(perform: prefillReply)
            .onChange(of: selectedPhotoItem) { item in
                guard let item else { return }
                Task { await importPhoto(item) }
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
            .sheet(isPresented: $showingTranslateSheet) {
                TranslateEmailView(sourceText: messageBody) { translated in
                    messageBody = translated
                }
            }
            .sheet(isPresented: $showingLinkSheet) {
                linkComposerSheet
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingScheduleSheet) {
                scheduleSheet
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingPreviewSheet) {
                markdownPreviewSheet
            }
            .sheet(isPresented: $showingDrawingSheet) {
                DrawingBoardView { export in
                    let attachment = MailMessage.MailAttachment(
                        id: UUID().uuidString,
                        fileName: export.fileName,
                        contentType: "image/png",
                        size: Int64(export.imageData.count)
                    )
                    draftAttachments.append(attachment)
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
            .sheet(isPresented: $showingAudioPicker) {
                FileImporterRepresentableView(
                    allowedContentTypes: [.audio],
                    allowsMultipleSelection: true
                ) { urls in
                    handleImportedAttachments(urls)
                    showingAudioPicker = false
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
    }

    private var recipientsSection: some View {
        Section("Recipients") {
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
                        .frame(minWidth: 180)
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var subjectSection: some View {
        Section("Subject") {
            TextField("Write a subject", text: $subject)
                .textInputAutocapitalization(.sentences)
                .disableAutocorrection(true)
        }
    }

    private var bodySection: some View {
        Section("Message") {
            ZStack(alignment: .topLeading) {
                if messageBody.isEmpty && !bodyFocused {
                    Text("Write your message…")
                        .foregroundColor(Color(.placeholderText))
                        .padding(.top, 8)
                        .padding(.leading, 6)
                }

                TextEditor(text: $messageBody)
                    .focused($bodyFocused)
                    .frame(minHeight: 280)
            }
        }
    }

    private var toolsSection: some View {
        Section("Tools") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    toolButton("AI Draft", icon: "sparkles") { showingAIPanel = true }
                    toolButton("Audio Notes", icon: "waveform") { showingAudioPicker = true }
                    toolButton("Translate", icon: "globe") { showingTranslateSheet = true }
                    toolButton("Clear Formatting", icon: "textformat.clear") { clearFormatting() }
                    toolButton("Schedule Send", icon: "calendar.badge.clock") { showingScheduleSheet = true }
                    toolButton("File Scanning", icon: "doc.text.viewfinder") { showingAttachmentPicker = true }
                    toolButton("Quoting", icon: "text.quote") { insertQuote() }
                    toolButton("Preview", icon: "doc.richtext") { showingPreviewSheet = true }
                    toolButton("Hyperlink", icon: "link") { showingLinkSheet = true }
                    toolButton("Drawing", icon: "pencil.and.outline") { showingDrawingSheet = true }
                    toolButton("Attach", icon: "paperclip") { showingAttachmentPicker = true }
                }
                .padding(.vertical, 4)
            }

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Label("Add Photo", systemImage: "photo.on.rectangle")
            }

            VStack(alignment: .leading, spacing: 8) {
                Label("Formatting Toolbar", systemImage: "textformat")
                    .font(.subheadline.weight(.semibold))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(formattingActions) { action in
                            Button {
                                insertMarkdown(action.insertion)
                            } label: {
                                Label(action.title, systemImage: action.icon)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(Color.indigo.opacity(0.14), in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private var attachmentsSection: some View {
        Section("Attachments") {
            if draftAttachments.isEmpty {
                Text("No attachments yet")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(draftAttachments) { attachment in
                    HStack {
                        Image(systemName: "paperclip")
                        VStack(alignment: .leading, spacing: 2) {
                            Text(attachment.fileName)
                            Text(ByteCountFormatter.string(fromByteCount: attachment.size, countStyle: .file))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button(role: .destructive) {
                            draftAttachments.removeAll { $0.id == attachment.id }
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
        }
    }

    private var scheduleSection: some View {
        Group {
            if let scheduleDate, scheduleDate > Date() {
                Section("Scheduled") {
                    HStack {
                        Label(scheduleDate.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                        Spacer()
                        Button("Clear") {
                            self.scheduleDate = nil
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
        }
    }

    private var linkComposerSheet: some View {
        NavigationStack {
            Form {
                TextField("Link text", text: $pendingLinkText)
                TextField("URL", text: $pendingLinkURL)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .keyboardType(.URL)
            }
            .navigationTitle("Insert Link")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showingLinkSheet = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Insert") {
                        let text = pendingLinkText.trimmingCharacters(in: .whitespacesAndNewlines)
                        let url = pendingLinkURL.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !text.isEmpty, !url.isEmpty else { return }
                        insert("[\(text)](\(url))")
                        showingLinkSheet = false
                    }
                    .disabled(pendingLinkText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || pendingLinkURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private var scheduleSheet: some View {
        NavigationStack {
            Form {
                DatePicker("Send at", selection: Binding(
                    get: { scheduleDate ?? Date().addingTimeInterval(3600) },
                    set: { scheduleDate = $0 }
                ), in: Date()..., displayedComponents: [.date, .hourAndMinute])
            }
            .navigationTitle("Schedule Send")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showingScheduleSheet = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showingScheduleSheet = false }
                }
            }
        }
    }

    private var markdownPreviewSheet: some View {
        NavigationStack {
            ScrollView {
                if let attributed = try? AttributedString(
                    markdown: messageBody,
                    options: AttributedString.MarkdownParsingOptions(
                        interpretedSyntax: .full,
                        failurePolicy: .returnPartiallyParsedIfPossible
                    )
                ) {
                    Text(attributed)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                } else {
                    Text(messageBody)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showingPreviewSheet = false }
                }
            }
        }
    }

    private var cannotSend: Bool {
        mergedRecipients().isEmpty || subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending
    }

    private func toolButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.12), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func prefillReply() {
        guard let reply = replyTo else { return }
        toRecipients = [reply.from]
        subject = "Re: \(reply.subject)"
        let dateString = DateFormatter.localizedString(from: reply.date, dateStyle: .medium, timeStyle: .short)
        let quotedBody = MailContentRenderer.render(htmlBody: reply.htmlBody, plainBody: reply.body).plainBody ?? reply.body
        messageBody = "\n\n--- On \(dateString), \(reply.from) wrote: ---\n\(quotedBody)"
    }

    private func commitRecipient() {
        let trimmed = newRecipient.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        toRecipients.append(trimmed)
        newRecipient = ""
    }

    private func recipientChip(_ recipient: String) -> some View {
        HStack(spacing: 6) {
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
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.12), in: Capsule())
        .foregroundColor(.blue)
    }

    private func insert(_ text: String) {
        if messageBody.isEmpty {
            messageBody = text
        } else {
            messageBody += "\n\(text)"
        }
    }
    
    private func insertMarkdown(_ snippet: String) {
        bodyFocused = true
        insert(snippet)
    }

    private func insertQuote() {
        let quoted = messageBody
            .split(separator: "\n")
            .map { "> \($0)" }
            .joined(separator: "\n")
        messageBody = quoted.isEmpty ? "> " : quoted
    }

    private func clearFormatting() {
        var normalized = messageBody
        let replacements: [(String, String)] = [
            ("\\*\\*", ""),
            ("__", ""),
            ("`", ""),
            ("\\[(.*?)\\]\\((.*?)\\)", "$1 ($2)")
        ]

        for (pattern, template) in replacements {
            normalized = normalized.replacingOccurrences(of: pattern, with: template, options: .regularExpression)
        }
        messageBody = normalized
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
                await MainActor.run { selectedPhotoItem = nil }
            }
        } catch {
            await MainActor.run {
                sendError = error.localizedDescription
                selectedPhotoItem = nil
            }
        }
    }

    private func handleScheduledOrImmediateSend() async {
        let now = Date()
        guard let scheduleDate, scheduleDate > now else {
            sendNow()
            return
        }

        let recipients = mergedRecipients()
        guard !recipients.isEmpty else { return }

        isSending = true
        do {
            let draft = MailDraft(
                from: account.emailAddress,
                to: recipients,
                cc: [],
                bcc: [],
                subject: subject,
                bodyText: messageBody
            )

            switch account.providerType {
            case .gmail:
                try await GmailProvider().saveDraft(session: providerSession(), draft: draft)
            case .outlook:
                try await OutlookProvider().saveDraft(session: providerSession(), draft: draft)
            case .yahoo:
                try await YahooMailProvider().saveDraft(session: providerSession(), draft: draft)
            case .proton:
                try await ProtonMailProvider().saveDraft(session: providerSession(), draft: draft)
            case .imap, .icloud:
                try await IMAPProvider().saveDraft(session: providerSession(), draft: draft)
            }

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

    private func sendNow() {
        let recipients = mergedRecipients()
        guard !recipients.isEmpty else { return }

        isSending = true
        Task {
            do {
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

                switch account.provider {
                case .gmail:
                    try await GmailMailProvider(account: account).sendMessage(message)
                case .icloud:
                    try await iCloudMailProvider(account: account).sendMessage(message)
                case .outlook:
                    try await OutlookProvider().sendMessage(session: providerSession(), draft: mailDraft(recipients: recipients))
                case .yahoo:
                    try await YahooMailProvider().sendMessage(session: providerSession(), draft: mailDraft(recipients: recipients))
                case .proton:
                    try await ProtonMailProvider().sendMessage(session: providerSession(), draft: mailDraft(recipients: recipients))
                case .imap:
                    try await IMAPProvider().sendMessage(session: providerSession(), draft: mailDraft(recipients: recipients))
                }

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

    private func mailDraft(recipients: [String]) -> MailDraft {
        MailDraft(
            from: account.emailAddress,
            to: recipients,
            cc: [],
            bcc: [],
            subject: subject,
            bodyText: messageBody
        )
    }

    private func providerSession() -> MailSession {
        MailSession(
            id: account.id,
            provider: account.providerType,
            email: account.emailAddress,
            displayName: account.displayName,
            accessToken: account.accessToken,
            refreshToken: account.refreshToken,
            imapHost: account.imapHost ?? "imap.mail.me.com",
            imapPort: account.imapPort ?? 993,
            smtpHost: account.smtpHost ?? "smtp.mail.me.com",
            smtpPort: account.smtpPort ?? 587
        )
    }

    private func mergedRecipients() -> [String] {
        var recipients = toRecipients
        let pendingRecipient = newRecipient.trimmingCharacters(in: .whitespacesAndNewlines)
        if !pendingRecipient.isEmpty {
            recipients.append(pendingRecipient)
        }
        return recipients
    }
}
