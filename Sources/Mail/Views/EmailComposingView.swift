import SwiftUI
import UniformTypeIdentifiers
import VisionKit
import UIKit

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
    @State private var showingTranslateSheet = false
    @State private var showingLinkSheet = false
    @State private var showingScheduleSheet = false
    @State private var showingDrawingSheet = false
    @State private var showingPreviewSheet = false
    @State private var showingDocumentScanner = false
    @State private var showingTableBuilder = false
    @State private var messageComposerMode: MessageComposerMode = .render

    @State private var scheduleDate: Date?
    @State private var pendingLinkText = ""
    @State private var pendingLinkURL = "https://"

    @FocusState private var bodyFocused: Bool

    private enum MessageComposerMode: String, CaseIterable, Identifiable {
        case render = "Rendered"
        case markdown = "Markdown"

        var id: String { rawValue }
    }
    
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
            .navigationTitle(replyTo == nil ? "Compose Email" : "Reply")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.headline.weight(.semibold))
                    }
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
                    .presentationDetents([.height(250)])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingPreviewSheet) {
                markdownPreviewSheet
            }
            .sheet(isPresented: $showingTableBuilder) {
                MailTableView { generatedTable in
                    insertMarkdown(generatedTable)
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showingDocumentScanner) {
                mailDocumentScannerSheet
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
            Picker("Composer Mode", selection: $messageComposerMode) {
                ForEach(MessageComposerMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            if messageComposerMode == .render {
                ScrollView {
                    Group {
                        if let attributed = parsedMarkdownBody {
                            Text(attributed)
                        } else if !messageBody.isEmpty {
                            Text(messageBody)
                        } else {
                            Text("Write your message…")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                }
                .frame(minHeight: 280)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))

                Button {
                    messageComposerMode = .markdown
                    bodyFocused = true
                } label: {
                    Label("Edit Markdown", systemImage: "square.and.pencil")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.bordered)
            } else {
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
    }

    private var toolsSection: some View {
        Section {
            Text("Compose faster with smart actions and clean formatting tools.")
                .font(.caption)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                modernToolButton(icon: "sparkles", title: "AI Draft", subtitle: "Generate content") { showingAIPanel = true }
                modernToolButton(icon: "globe", title: "Translate", subtitle: "Change language") { showingTranslateSheet = true }
                modernToolButton(icon: "calendar.badge.clock", title: "Schedule", subtitle: "Send later") { showingScheduleSheet = true }
                modernToolButton(icon: "doc.viewfinder", title: "Scan", subtitle: "Scan documents") { showingDocumentScanner = true }
                modernToolButton(icon: "paperclip", title: "Attach", subtitle: "Add files") { showingAttachmentPicker = true }
                modernToolButton(icon: "waveform", title: "Audio Notes", subtitle: "Attach audio") { showingAudioPicker = true }
                modernToolButton(icon: "tablecells", title: "Table", subtitle: "Build table UI") { showingTableBuilder = true }
                modernToolButton(icon: "doc.richtext", title: "Preview", subtitle: "Rendered output") { showingPreviewSheet = true }
                modernToolButton(icon: "link", title: "Link", subtitle: "Insert hyperlink") { showingLinkSheet = true }
                modernToolButton(icon: "text.quote", title: "Quote", subtitle: "Quote body") { insertQuote() }
                modernToolButton(icon: "textformat.clear", title: "Clear", subtitle: "Remove markdown") { clearFormatting() }
                modernToolButton(icon: "pencil.and.outline", title: "Drawing", subtitle: "Attach sketch") { showingDrawingSheet = true }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(formattingActions) { action in
                        Button {
                            insertMarkdown(action.insertion)
                        } label: {
                            Image(systemName: action.icon)
                                .frame(width: 34, height: 34)
                                .background(Color.indigo.opacity(0.14), in: Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(action.title)
                    }
                }
                .padding(.vertical, 2)
            }
        } header: {
            Text("Tools")
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

    @ViewBuilder
    private var mailDocumentScannerSheet: some View {
        if VNDocumentCameraViewController.isSupported {
            MailDocumentScannerRepresentable { scannedImages in
                appendScannedAttachments(scannedImages)
                showingDocumentScanner = false
            }
            .ignoresSafeArea()
        } else {
            NavigationStack {
                ContentUnavailableView(
                    "Scanner Unavailable",
                    systemImage: "camera.metering.unknown",
                    description: Text("Document scanning is not supported on this device.")
                )
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { showingDocumentScanner = false }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    private var cannotSend: Bool {
        mergedRecipients().isEmpty || subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending
    }

    private var parsedMarkdownBody: AttributedString? {
        try? AttributedString(
            markdown: messageBody,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .full,
                failurePolicy: .returnPartiallyParsedIfPossible
            )
        )
    }

    private func modernToolButton(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 30, height: 30)
                    .background(Color.blue.opacity(0.14), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(8)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
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
        insert(snippet)
        if messageComposerMode == .markdown {
            bodyFocused = true
        }
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

    private func appendScannedAttachments(_ images: [UIImage]) {
        for image in images {
            guard let data = image.jpegData(compressionQuality: 0.88) else { continue }
            let attachment = MailMessage.MailAttachment(
                id: UUID().uuidString,
                fileName: "Scan-\(draftAttachments.count + 1).jpg",
                contentType: "image/jpeg",
                size: Int64(data.count)
            )
            draftAttachments.append(attachment)
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

private struct MailDocumentScannerRepresentable: UIViewControllerRepresentable {
    let onComplete: ([UIImage]) -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onComplete: ([UIImage]) -> Void

        init(onComplete: @escaping ([UIImage]) -> Void) {
            self.onComplete = onComplete
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            onComplete([])
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            onComplete([])
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var scannedImages: [UIImage] = []
            for index in 0..<scan.pageCount {
                scannedImages.append(scan.imageOfPage(at: index))
            }
            onComplete(scannedImages)
        }
    }
}
