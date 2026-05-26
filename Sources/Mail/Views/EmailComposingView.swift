import SwiftUI
import UniformTypeIdentifiers
import VisionKit
import UIKit

struct EmailComposingView: View {
    @Environment(\.dismiss) private var dismiss

    let account: MailAccount
    var replyTo: MailMessage? = nil

    @State private var toRecipients: [String] = []
    @State private var ccRecipients: [String] = []
    @State private var bccRecipients: [String] = []
    @State private var newRecipient = ""
    @State private var newCCRecipient = ""
    @State private var newBCCRecipient = ""
    @State private var subject = ""
    @State private var messageBody = ""
    @State private var draftAttachments: [MailMessage.MailAttachment] = []

    @State private var isSending = false
    @State private var sendError: String?
    @State private var showingAIPanel = false
    @State private var showingAttachmentPicker = false
    @State private var showingTranslateSheet = false
    @State private var showingLinkSheet = false
    @State private var showingScheduleSheet = false
    @State private var showingDrawingSheet = false
    @State private var showingPreviewSheet = false
    @State private var showingDocumentScanner = false
    @State private var showingTableBuilder = false
    @State private var showingAIWrite = false
    @State private var showingCCBCC = false
    @State private var showingFormattingBar = false
    @State private var showingDraftsSheet = false
    @State private var showingCancelAlert = false

    @State private var scheduleDate: Date?
    @State private var selectedFromAccountID: String = ""
    @State private var pendingLinkText = ""
    @State private var pendingLinkURL = "https://"
    @State private var pendingUndoSendTask: Task<Void, Never>?
    @State private var showUndoSendBanner = false
    @State private var undoCountdown = 0

    @AppStorage("mail.settings.defaultSenderAccountId") private var defaultSenderAccountId = ""
    @AppStorage("mail.settings.undoSendEnabled") private var undoSendEnabled = true
    @AppStorage("mail.settings.undoSendDelay") private var undoSendDelay = 5

    @FocusState private var focusedField: ComposeField?

    private enum ComposeField: Hashable {
        case to, cc, bcc, subject, body
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Color(.systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    header

                    ScrollView {
                        VStack(spacing: 16) {
                            fieldsContainer
                                .padding(.top, 16)

                            editorContainer

                            if !draftAttachments.isEmpty {
                                attachmentsSection
                                    .padding(.horizontal, 16)
                            }

                            if !messageBody.isEmpty && showingPreviewSheet == false {
                                livePreview
                                    .padding(.horizontal, 16)
                            }

                            Spacer(minLength: 120)
                        }
                    }
                }

                VStack {
                    Spacer()
                    if focusedField == .body {
                        formattingBar
                            .clipShape(Capsule())
                            .shadow(radius: 4)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        composeToolbar
                            .clipShape(Capsule())
                            .shadow(radius: 4)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }

                if !isSending {
                    sendButton
                }
            }
            .navigationBarHidden(true)
            .onAppear(perform: prefillReply)
            .onAppear {
                selectedFromAccountID = resolvedDefaultAccountID()
                focusedField = replyTo == nil ? .to : .body
            }
            .onDisappear {
                pendingUndoSendTask?.cancel()
                pendingUndoSendTask = nil
            }
            .overlay(alignment: .bottom) {
                if showUndoSendBanner {
                    undoSendBannerView
                        .padding(.bottom, 100)
                }
            }
            .sheet(isPresented: $showingAIPanel) {
                DraftingEmailsView(currentBody: messageBody) { result in
                    applyAIDraft(result)
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showingAIWrite) {
                AIWriteView { generated in
                    insertMarkdown(generated)
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showingTranslateSheet) {
                TranslateEmailView(sourceText: messageBody) { translated in
                    messageBody = translated
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showingLinkSheet) {
                linkComposerSheet
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showingScheduleSheet) {
                scheduleSheet
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showingTableBuilder) {
                MailTableView { generatedTable in
                    insertMarkdown(generatedTable)
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showingDocumentScanner) {
                mailDocumentScannerSheet
                .presentationDetents([.large])
            }
            .sheet(isPresented: $showingDrawingSheet) {
                DrawingBoardView { export in
                    addAttachment(from: export)
                }
                .presentationDetents([.large])
            }
            .sheet(isPresented: $showingAttachmentPicker) {
                FileImporterView(allowedContentTypes: [.data, .image, .pdf, .text], allowsMultipleSelection: true) { urls in
                    handleImportedAttachments(urls)
                }
            }
            .sheet(isPresented: $showingPreviewSheet) {
                emailPreviewSheet
                .presentationDetents([.large])
            }
            .sheet(isPresented: $showingDraftsSheet) {
                EmailComposeDraftsView { draft in
                    loadDraft(draft)
                }
                .presentationDetents([.large])
            }
            .alert("Unsent Email", isPresented: $showingCancelAlert) {
                Button("Save Draft", role: .none) {
                    saveDraft()
                    dismiss()
                }
                Button("Discard", role: .destructive) {
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("You have unsent content. Would you like to save it as a draft or discard it?")
            }
        }
    }

    private var header: some View {
        HStack {
            Button("Cancel") {
                if hasUnsavedContent { showingCancelAlert = true }
                else { dismiss() }
            }
            .foregroundStyle(.primary)

            Spacer()

            Text(replyTo == nil ? "New Message" : "Reply")
                .font(.headline)

            Spacer()

            Button {
                showingDraftsSheet = true
            } label: {
                Image(systemName: "tray.full")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }

    private var fieldsContainer: some View {
        VStack(spacing: 0) {
            fromRow
            Divider().padding(.leading, 16)
            toRow
            Divider().padding(.leading, 16)
            if showingCCBCC {
                ccRow
                Divider().padding(.leading, 16)
                bccRow
                Divider().padding(.leading, 16)
            }
            subjectRow
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal, 16)
    }

    private var fromRow: some View {
        HStack {
            Text("From:").foregroundColor(.secondary)
            Picker("", selection: $selectedFromAccountID) {
                ForEach(availableAccounts) { acc in Text(acc.emailAddress).tag(acc.id) }
            }
            .pickerStyle(.menu)
            Spacer()
        }
        .padding(12)
    }

    private var toRow: some View {
        HStack(alignment: .top) {
            Text("To:").foregroundColor(.secondary).padding(.top, 8)
            VStack(alignment: .leading, spacing: 6) {
                if !toRecipients.isEmpty {
                    WrappingFlowLayout(spacing: 6) {
                        ForEach(toRecipients, id: \.self) { r in
                            recipientChip(r) { toRecipients.removeAll { $0 == r } }
                        }
                    }
                }
                TextField("Recipient", text: $newRecipient)
                    .focused($focusedField, equals: .to)
                    .onSubmit { commitRecipient() }
            }
            Button { withAnimation { showingCCBCC.toggle() } } label: {
                Text(showingCCBCC ? "Hide" : "Cc/Bcc").font(.caption)
            }
        }
        .padding(12)
    }

    private var ccRow: some View {
        HStack(alignment: .top) {
            Text("Cc:").foregroundColor(.secondary).padding(.top, 8)
            VStack(alignment: .leading, spacing: 6) {
                if !ccRecipients.isEmpty {
                    WrappingFlowLayout(spacing: 6) {
                        ForEach(ccRecipients, id: \.self) { r in
                            recipientChip(r) { ccRecipients.removeAll { $0 == r } }
                        }
                    }
                }
                TextField("Cc", text: $newCCRecipient)
                    .focused($focusedField, equals: .cc)
                    .onSubmit {
                        let trimmed = newCCRecipient.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty { ccRecipients.append(trimmed); newCCRecipient = "" }
                    }
            }
        }
        .padding(12)
    }

    private var bccRow: some View {
        HStack(alignment: .top) {
            Text("Bcc:").foregroundColor(.secondary).padding(.top, 8)
            VStack(alignment: .leading, spacing: 6) {
                if !bccRecipients.isEmpty {
                    WrappingFlowLayout(spacing: 6) {
                        ForEach(bccRecipients, id: \.self) { r in
                            recipientChip(r) { bccRecipients.removeAll { $0 == r } }
                        }
                    }
                }
                TextField("Bcc", text: $newBCCRecipient)
                    .focused($focusedField, equals: .bcc)
                    .onSubmit {
                        let trimmed = newBCCRecipient.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty { bccRecipients.append(trimmed); newBCCRecipient = "" }
                    }
            }
        }
        .padding(12)
    }

    private var subjectRow: some View {
        HStack {
            Text("Subject:").foregroundColor(.secondary)
            TextField("Subject", text: $subject)
                .focused($focusedField, equals: .subject)
        }
        .padding(12)
    }

    private var editorContainer: some View {
        VStack {
            bodyEditor
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal, 16)
    }

    private var sendButton: some View {
        Button(action: {
            if scheduleDate != nil { Task { await handleScheduledOrImmediateSend() } }
            else { sendNow() }
        }) {
            if isSending {
                ProgressView().tint(.white)
            } else {
                Image(systemName: scheduleDate != nil ? "calendar.badge.clock" : "paperplane.fill")
                    .font(.system(size: 20, weight: .bold))
            }
        }
        .frame(width: 52, height: 52)
        .background(Color.accentColor)
        .foregroundColor(.white)
        .clipShape(Circle())
        .padding(20)
        .shadow(radius: 4)
    }

    // MARK: - Body Editor

    private var bodyEditor: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $messageBody)
                .focused($focusedField, equals: .body)
                .frame(minHeight: 300)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 12)

            if messageBody.isEmpty {
                Text("Compose your email...")
                    .font(.body)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 8)
                    .padding(.leading, 16)
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Live Preview

    private var livePreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Preview", systemImage: "eye.fill")
                    .font(.caption2.bold())
                    .foregroundStyle(.blue)
                Spacer()
                Button {
                    showingPreviewSheet = true
                } label: {
                    Text("Full Preview")
                        .font(.caption2.bold())
                        .foregroundStyle(.blue)
                }
            }

            MarkdownPreview(text: normalizedBody)
                .font(.subheadline)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Formatting Bar

    private var formattingBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                formatButton("bold", "**bold**")
                formatButton("italic", "_italic_")
                formatButton("textformat.size", "## ")
                formatButton("list.bullet", "- ")
                formatButton("checklist", "- [ ] ")
                formatButton("chevron.left.forwardslash.chevron.right", "```\ncode\n```")
                formatButton("minus", "---")
                formatButton("link", "[text](url)")

                Divider()
                    .frame(height: 24)
                    .padding(.horizontal, 4)

                Button { showingLinkSheet = true } label: {
                    Image(systemName: "link.badge.plus")
                        .font(.system(size: 15, weight: .medium))
                        .frame(width: 36, height: 36)
                }
                Button { showingTableBuilder = true } label: {
                    Image(systemName: "tablecells")
                        .font(.system(size: 15, weight: .medium))
                        .frame(width: 36, height: 36)
                }

                Button { focusedField = nil } label: {
                    Image(systemName: "keyboard.chevron.compact.down")
                        .font(.system(size: 15, weight: .medium))
                        .frame(width: 36, height: 36)
                        .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal, 12)
        }
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
    }

    private func formatButton(_ icon: String, _ insertion: String) -> some View {
        Button {
            insertMarkdown(insertion)
        } label: {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .frame(width: 36, height: 36)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Compose Toolbar

    private var composeToolbar: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    toolbarButton("paperclip", .blue) { showingAttachmentPicker = true }
                    toolbarButton("scanner", .orange) { showingDocumentScanner = true }
                    toolbarButton("pencil.tip.crop.circle", .pink) { showingDrawingSheet = true }
                    toolbarButton("sparkles.rectangle.stack", .purple) { showingAIWrite = true }
                    toolbarButton("globe", .cyan) { showingTranslateSheet = true }
                    toolbarButton("calendar.badge.clock", .green) { showingScheduleSheet = true }
                    toolbarButton("sparkles", .indigo) { showingAIPanel = true }
                }
                .padding(.horizontal, 12)
            }
        }
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    private func toolbarButton(_ icon: String, _ color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(color)
        }
    }

    // MARK: - Attachments

    private var attachmentsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Attachments (\(draftAttachments.count))")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            ForEach(draftAttachments) { attachment in
                HStack(spacing: 10) {
                    Image(systemName: attachmentIcon(attachment.contentType))
                        .foregroundStyle(.blue)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(attachment.fileName)
                            .font(.subheadline)
                            .lineLimit(1)
                        if attachment.size > 0 {
                            Text(ByteCountFormatter.string(fromByteCount: attachment.size, countStyle: .file))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    Spacer()
                    Button {
                        draftAttachments.removeAll { $0.id == attachment.id }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(10)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private func attachmentIcon(_ contentType: String) -> String {
        if contentType.hasPrefix("image/") { return "photo.fill" }
        if contentType.hasPrefix("video/") { return "film.fill" }
        if contentType.contains("pdf") { return "doc.richtext" }
        return "doc.fill"
    }

    // MARK: - Undo Send Banner

    private var undoSendBannerView: some View {
        HStack {
            Text("Sending In \(undoCountdown)s…")
                .font(.subheadline.bold())
            Spacer()
            Button("Undo") { cancelPendingUndoSend() }
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color.blue, in: Capsule())
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 8)
        .padding(.horizontal)
    }

    // MARK: - Email Preview Sheet

    private var emailPreviewSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Group {
                        HStack {
                            Text("From:")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            Text(availableAccounts.first { $0.id == selectedFromAccountID }?.emailAddress ?? account.emailAddress)
                                .font(.caption)
                        }
                        HStack {
                            Text("To:")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            Text(toRecipients.joined(separator: ", "))
                                .font(.caption)
                        }
                        if !subject.isEmpty {
                            Text(subject)
                                .font(.title3.bold())
                        }
                    }

                    Divider()

                    MarkdownPreview(text: normalizedBody)
                        .font(.body)
                        .textSelection(.enabled)
                }
                .padding()
            }
            .navigationTitle("Email Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showingPreviewSheet = false }.bold()
                }
            }
        }
    }

    // MARK: - Recipient Chip

    private func recipientChip(_ recipient: String, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 4) {
            Text(recipient)
                .font(.caption)
                .lineLimit(1)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.blue.opacity(0.15), in: Capsule())
        .foregroundStyle(.blue)
    }

    // MARK: - Logic

    private func applyAIDraft(_ result: DraftingEmailResult) {
        if !result.recipient.isEmpty { toRecipients.append(result.recipient) }
        if !result.subject.isEmpty { subject = result.subject }
        messageBody = result.body
    }

    private func insertMarkdown(_ text: String) {
        if messageBody.isEmpty {
            messageBody = text
        } else {
            messageBody += "\n\n" + text
        }
        focusedField = .body
    }

    private func addAttachment(from export: DrawingExport) {
        let attachment = MailMessage.MailAttachment(
            id: UUID().uuidString,
            fileName: export.fileName,
            contentType: "image/png",
            size: Int64(export.imageData.count)
        )
        draftAttachments.append(attachment)
    }

    private func commitRecipient() {
        let trimmed = newRecipient.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            toRecipients.append(trimmed)
            newRecipient = ""
        }
    }

    private func prefillReply() {
        guard let reply = replyTo else { return }
        toRecipients = [reply.from]
        subject = "Re: \(reply.subject)"
        messageBody = "\n\n\n--- On \(reply.date.formatted()), \(reply.from) wrote: ---\n\(reply.body)"
    }

    private var cannotSend: Bool {
        toRecipients.isEmpty || subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || messageBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending
    }

    private var hasUnsavedContent: Bool {
        !toRecipients.isEmpty || !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !messageBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var normalizedBody: String {
        EmailBodyNormalizer.normalize(messageBody)
    }

    private func saveDraft() {
        guard hasUnsavedContent else { return }
        let draft = EmailComposeDraft(
            id: UUID().uuidString,
            toRecipients: toRecipients,
            ccRecipients: ccRecipients,
            bccRecipients: bccRecipients,
            subject: subject,
            body: messageBody,
            savedAt: Date()
        )
        EmailComposeDraftStore.shared.save(draft)
    }

    private func loadDraft(_ draft: EmailComposeDraft) {
        toRecipients = draft.toRecipients
        ccRecipients = draft.ccRecipients
        bccRecipients = draft.bccRecipients
        subject = draft.subject
        messageBody = draft.body
    }

    private func sendNow() {
        if undoSendEnabled {
            scheduleUndoSend()
        } else {
            executeSend()
        }
    }

    private func executeSend() {
        isSending = true
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await MainActor.run {
                isSending = false
                dismiss()
            }
        }
    }

    private func scheduleUndoSend() {
        undoCountdown = undoSendDelay
        showUndoSendBanner = true
        pendingUndoSendTask = Task {
            while undoCountdown > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }
                await MainActor.run { undoCountdown -= 1 }
            }
            await MainActor.run {
                showUndoSendBanner = false
                executeSend()
            }
        }
    }

    private func cancelPendingUndoSend() {
        pendingUndoSendTask?.cancel()
        showUndoSendBanner = false
        isSending = false
    }

    private func handleImportedAttachments(_ urls: [URL]) {
        for url in urls {
            let attachment = MailMessage.MailAttachment(
                id: UUID().uuidString,
                fileName: url.lastPathComponent,
                contentType: "application/octet-stream",
                size: 0
            )
            draftAttachments.append(attachment)
        }
    }

    private var availableAccounts: [MailAccount] {
        MailStore.shared.accounts
    }

    private func resolvedDefaultAccountID() -> String {
        availableAccounts.first { $0.id == defaultSenderAccountId }?.id ?? account.id
    }

    private func handleScheduledOrImmediateSend() async {
        executeSend()
    }

    private var linkComposerSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Display Text", text: $pendingLinkText)
                    TextField("URL", text: $pendingLinkURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                }
            }
            .navigationTitle("Insert Link")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingLinkSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Insert") {
                        insertMarkdown("[\(pendingLinkText)](\(pendingLinkURL))")
                        showingLinkSheet = false
                    }
                    .bold()
                }
            }
        }
    }

    private var scheduleSheet: some View {
        NavigationStack {
            DatePicker("Send At", selection: Binding(get: { scheduleDate ?? Date() }, set: { scheduleDate = $0 }), in: Date()...)
                .datePickerStyle(.graphical)
                .navigationTitle("Schedule Send")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { showingScheduleSheet = false }.bold()
                    }
                }
        }
    }

    private var mailDocumentScannerSheet: some View {
        #if os(iOS)
        MailDocScanView { scan in
            handleDocumentScan(scan)
            showingDocumentScanner = false
        } onCancel: {
            showingDocumentScanner = false
        } onError: { error in
            sendError = error.localizedDescription
            showingDocumentScanner = false
        }
        #else
        Text("Document Scanning is not supported on this platform, switch to iOS to proceed.")
        #endif
    }

    #if os(iOS)
    private func handleDocumentScan(_ scan: VNDocumentCameraScan) {
        for pageIndex in 0..<scan.pageCount {
            let image = scan.imageOfPage(at: pageIndex)
            if let data = image.jpegData(compressionQuality: 0.8) {
                let attachment = MailMessage.MailAttachment(
                    id: UUID().uuidString,
                    fileName: "Scanned Document \(pageIndex + 1).jpg",
                    contentType: "image/jpeg",
                    size: Int64(data.count)
                )
                draftAttachments.append(attachment)
            }
        }
    }
    #endif
}

struct WrappingFlowLayout: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var height: CGFloat = 0
        var width: CGFloat = 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity
        for size in sizes {
            if currentX + size.width > maxWidth {
                currentX = 0
                currentY += height + spacing
                height = 0
            }
            currentX += size.width + spacing
            height = max(height, size.height)
            width = max(width, currentX)
        }
        return CGSize(width: width, height: currentY + height)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0
        for (index, subview) in subviews.enumerated() {
            if currentX + sizes[index].width > bounds.maxX {
                currentX = bounds.minX
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            currentX += sizes[index].width + spacing
            lineHeight = max(lineHeight, sizes[index].height)
        }
    }
}

struct MarkdownPreview: View {
    let text: String
    var body: some View {
        let normalized = EmailBodyNormalizer.normalize(text)
        if let attributed = try? AttributedString(markdown: normalized, options: .init(interpretedSyntax: .full)) {
            Text(attributed)
                .lineSpacing(2)
        } else {
            Text(normalized)
                .lineSpacing(2)
        }
    }
}

// MARK: - Email Body Normalizer

enum EmailBodyNormalizer {
    static func normalize(_ body: String) -> String {
        var result = body
        result = result.replacingOccurrences(of: "\\n", with: "\n")
        result = result.replacingOccurrences(of: "\r\n", with: "\n")
        return result
    }

    static func toHTML(_ body: String) -> String {
        let normalized = normalize(body)
        let escaped = normalized
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
        return escaped.replacingOccurrences(of: "\n", with: "<br>")
    }
}

// MARK: - Compose Draft Model

struct EmailComposeDraft: Codable, Identifiable {
    let id: String
    var toRecipients: [String]
    var ccRecipients: [String]
    var bccRecipients: [String]
    var subject: String
    var body: String
    var savedAt: Date
}

// MARK: - Compose Draft Store

final class EmailComposeDraftStore {
    static let shared = EmailComposeDraftStore()
    private let fileManager = FileManager.default

    private var storageURL: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Workspace/Mail/ComposeDrafts", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent("drafts.json")
    }

    func save(_ draft: EmailComposeDraft) {
        var drafts = loadAll()
        if let idx = drafts.firstIndex(where: { $0.id == draft.id }) {
            drafts[idx] = draft
        } else {
            drafts.insert(draft, at: 0)
        }
        persist(drafts)
    }

    func loadAll() -> [EmailComposeDraft] {
        guard fileManager.fileExists(atPath: storageURL.path),
              let data = try? Data(contentsOf: storageURL),
              let decoded = try? JSONDecoder().decode([EmailComposeDraft].self, from: data) else {
            return []
        }
        return decoded.sorted { $0.savedAt > $1.savedAt }
    }

    func delete(_ draftID: String) {
        var drafts = loadAll()
        drafts.removeAll { $0.id == draftID }
        persist(drafts)
    }

    private func persist(_ drafts: [EmailComposeDraft]) {
        guard let data = try? JSONEncoder().encode(drafts) else { return }
        try? data.write(to: storageURL)
    }
}

// MARK: - Compose Drafts View

struct EmailComposeDraftsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var drafts: [EmailComposeDraft] = []
    let onSelect: (EmailComposeDraft) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if drafts.isEmpty {
                    ContentUnavailableView("No Drafts", systemImage: "tray", description: Text("All your saved drafts will appear here."))
                } else {
                    List {
                        ForEach(drafts) { draft in
                            Button {
                                onSelect(draft)
                                dismiss()
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(draft.subject.isEmpty ? "(No Subject)" : draft.subject)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    if !draft.toRecipients.isEmpty {
                                        Text("To: \(draft.toRecipients.joined(separator: ", "))")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                    Text(draft.body)
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                        .lineLimit(2)
                                    Text(draft.savedAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption2)
                                        .foregroundStyle(.quaternary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete { offsets in
                            let idsToDelete = offsets.map { drafts[$0].id }
                            for id in idsToDelete {
                                EmailComposeDraftStore.shared.delete(id)
                            }
                            drafts.remove(atOffsets: offsets)
                        }
                    }
                }
            }
            .navigationTitle("Saved Drafts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.bold()
                }
            }
            .onAppear {
                drafts = EmailComposeDraftStore.shared.loadAll()
            }
        }
    }
}
