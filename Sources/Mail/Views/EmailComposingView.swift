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
    @State private var showingAIWrite = false

    @State private var scheduleDate: Date?
    @State private var selectedFromAccountID: String = ""
    @State private var pendingLinkText = ""
    @State private var pendingLinkURL = "https://"
    @State private var pendingUndoSendTask: Task<Void, Never>?
    @State private var showUndoSendBanner = false
    @State private var undoCountdown = 0

    @AppStorage("mail.settings.defaultSenderAccountId") private var defaultSenderAccountId = ""
    @AppStorage("mail.settings.undoSendEnabled") private var undoSendEnabled = true
    @AppStorage("mail.settings.undoSendDelay") private var undoSendDelay = 10

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
        MarkdownFormatAction(title: "Heading", icon: "textformat.size", insertion: "## Heading"),
        MarkdownFormatAction(title: "Bullet List", icon: "list.bullet", insertion: "- First item\n- Second item"),
        MarkdownFormatAction(title: "Checklist", icon: "checklist", insertion: "- [ ] Todo item"),
        MarkdownFormatAction(title: "Code Block", icon: "terminal", insertion: "```\ncode block\n```"),
        MarkdownFormatAction(title: "Divider", icon: "minus", insertion: "---")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.workspaceBackground.ignoresSafeArea()

                Form {
                    Section {
                        fromSection
                        recipientsSection
                        subjectSection
                    }
                    .listRowBackground(Color.workspaceSurface)

                    Section {
                        bodySection
                        attachmentsSection
                    }
                    .listRowBackground(Color.workspaceSurface)

                    Section {
                        compactToolsGrid
                    }
                    .listRowBackground(Color.workspaceSurface)

                    if scheduleDate != nil {
                        scheduleSection
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(replyTo == nil ? "Compose" : "Reply")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.secondary)
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showingAIPanel = true
                    } label: {
                        Image(systemName: "sparkles")
                            .foregroundStyle(LinearGradient(colors: [.aiGradientStart, .aiGradientEnd], startPoint: .topLeading, endPoint: .bottomTrailing))
                    }

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
                            Text(scheduleDate != nil ? "Schedule" : "Send")
                                .fontWeight(.bold)
                        }
                    }
                    .disabled(cannotSend)
                }
            }
            .onAppear(perform: prefillReply)
            .onAppear {
                selectedFromAccountID = resolvedDefaultAccountID()
            }
            .onDisappear {
                pendingUndoSendTask?.cancel()
                pendingUndoSendTask = nil
            }
            .overlay(alignment: .bottom) {
                if showUndoSendBanner {
                    undoSendBannerView
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
        }
    }

    private var fromSection: some View {
        HStack {
            Text("From:")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)

            Picker("", selection: $selectedFromAccountID) {
                ForEach(availableAccounts) { account in
                    Text(account.emailAddress).tag(account.id)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
        }
    }

    private var recipientsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("To:")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)

                TextField("Recipients", text: $newRecipient)
                    .textInputAutocapitalization(.never)
                    .onSubmit { commitRecipient() }
            }

            if !toRecipients.isEmpty {
                WrappingFlowLayout(spacing: 8) {
                    ForEach(toRecipients, id: \.self) { recipient in
                        recipientChip(recipient)
                    }
                }
            }
        }
    }

    private var subjectSection: some View {
        HStack {
            Text("Subject:")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)

            TextField("", text: $subject)
        }
    }

    private var bodySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .topLeading) {
                TextEditor(text: $messageBody)
                    .focused($bodyFocused)
                    .frame(minHeight: 250)
                    .opacity(messageBody.isEmpty ? 0.25 : 1.0)

                if messageBody.isEmpty && !bodyFocused {
                    Text("Compose Email")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                        .padding(.leading, 4)
                        .allowsHitTesting(false)
                }
            }

            if !messageBody.isEmpty {
                Divider()
                Label("Markdown Rendering", systemImage: "eye.fill")
                    .font(.caption2.bold())
                    .foregroundStyle(.blue)

                MarkdownPreview(text: messageBody)
                    .font(.subheadline)
                    .padding(12)
                    .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.vertical, 8)
    }

    private var compactToolsGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    toolButton(icon: "sparkles", color: .purple, action: { showingAIWrite = true })
                    toolButton(icon: "paperclip", color: .blue, action: { showingAttachmentPicker = true })
                    toolButton(icon: "doc.viewfinder", color: .orange, action: { showingDocumentScanner = true })
                    toolButton(icon: "calendar.badge.clock", color: .green, action: { showingScheduleSheet = true })
                    toolButton(icon: "globe", color: .cyan, action: { showingTranslateSheet = true })
                    toolButton(icon: "tablecells", color: .indigo, action: { showingTableBuilder = true })
                    toolButton(icon: "link", color: .blue, action: { showingLinkSheet = true })
                    toolButton(icon: "pencil.and.outline", color: .pink, action: { showingDrawingSheet = true })
                }
                .padding(.horizontal, 2)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(formattingActions) { action in
                        Button {
                            insertMarkdown(action.insertion)
                        } label: {
                            Image(systemName: action.icon)
                                .font(.system(size: 14, weight: .bold))
                                .frame(width: 40, height: 40)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .padding(.vertical, 14)
    }

    private func toolButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(color)
            }
            .frame(width: 48, height: 48)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.1), lineWidth: 1))
            .shadow(color: color.opacity(0.1), radius: 4)
        }
        .buttonStyle(.plain)
    }

    private var attachmentsSection: some View {
        Group {
            if !draftAttachments.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Attachments (\(draftAttachments.count))")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ForEach(draftAttachments) { attachment in
                        HStack {
                            Image(systemName: "doc.fill")
                                .foregroundStyle(.blue)
                            Text(attachment.fileName)
                                .font(.subheadline)
                            Spacer()
                            Button {
                                draftAttachments.removeAll { $0.id == attachment.id }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(10)
                        .background(Color.workspaceSurface, in: RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
    }

    private var scheduleSection: some View {
        Section {
            HStack {
                Label("Scheduled for \(scheduleDate?.formatted() ?? "")", systemImage: "clock.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(.orange)
                Spacer()
                Button("Cancel") { scheduleDate = nil }
                    .font(.caption.bold())
                    .foregroundStyle(.red)
            }
        }
    }

    private var undoSendBannerView: some View {
        HStack {
            Text("Sending In \(undoCountdown)s...")
                .font(.subheadline.bold())
            Spacer()
            Button("Undo") { cancelPendingUndoSend() }
                .font(.subheadline.bold())
                .foregroundStyle(.blue)
        }
        .padding()
        .background(.ultraThinMaterial, in: Capsule())
        .padding()
    }

    // Logic and Helpers

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
        bodyFocused = true
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

    private func recipientChip(_ recipient: String) -> some View {
        HStack(spacing: 6) {
            Text(recipient)
                .font(.caption.bold())
            Button { toRecipients.removeAll { $0 == recipient } } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.2), in: Capsule())
        .foregroundStyle(.blue)
    }

    private func prefillReply() {
        guard let reply = replyTo else { return }
        toRecipients = [reply.from]
        subject = "Re: \(reply.subject)"
        messageBody = "\n\n\n--- On \(reply.date.formatted()), \(reply.from) wrote: ---\n\(reply.body)"
    }
    
    private var cannotSend: Bool {
        toRecipients.isEmpty || subject.isEmpty || isSending
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
            // Mocking send for simulation
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
                TextField("Text", text: $pendingLinkText)
                TextField("URL", text: $pendingLinkURL)
            }
            .navigationTitle("Insert Link")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Insert") {
                        insertMarkdown("[\(pendingLinkText)](\(pendingLinkURL))")
                        showingLinkSheet = false
                    }
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
                        Button("Done") { showingScheduleSheet = false }
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
        Text("Document Scanning is not supported on this platform.")
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
        if let attributed = try? AttributedString(markdown: text, options: .init(interpretedSyntax: .full)) {
            Text(attributed)
        } else {
            Text(text)
        }
    }
}
