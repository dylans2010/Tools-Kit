import SwiftUI

struct EmailComposingView: View {
    @Environment(\.dismiss) var dismiss
    let account: MailAccount
    var replyTo: MailMessage? = nil

    @State private var to = ""
    @State private var subject = ""
    @State private var body = ""
    @State private var isSending = false
    @State private var showingAISuggestions = false
    @State private var aiContext = ""
    @State private var isGeneratingAI = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("To:", text: $to)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    TextField("Subject:", text: $subject)
                }

                Section {
                    TextEditor(text: $body)
                        .frame(minHeight: 300)
                        .overlay(
                            Group {
                                if body.isEmpty {
                                    Text("Write your message here...")
                                        .foregroundColor(.secondary)
                                        .padding(.top, 8)
                                        .padding(.leading, 4)
                                }
                            },
                            alignment: .topLeading
                        )
                }
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
                        }

                        Button(action: send) {
                            if isSending {
                                ProgressView()
                            } else {
                                Image(systemName: "paperplane.fill")
                            }
                        }
                        .disabled(to.isEmpty || subject.isEmpty || body.isEmpty || isSending)
                    }
                }
            }
            .onAppear {
                if let reply = replyTo {
                    to = reply.from
                    subject = "Re: \(reply.subject)"
                    body = "\n\n--- On \(reply.date.description) \(reply.from) wrote: ---\n\(reply.body)"
                }
            }
            .sheet(isPresented: $showingAISuggestions) {
                VStack(spacing: 20) {
                    Text("AI Writing Assistant")
                        .font(.headline)

                    TextField("What do you want to say?", text: $aiContext)
                        .textFieldStyle(.roundedBorder)
                        .padding()

                    HStack {
                        Button("Professional") { generateDraft(tone: "professional") }
                        Button("Casual") { generateDraft(tone: "casual") }
                        Button("Friendly") { generateDraft(tone: "friendly") }
                    }
                    .buttonStyle(.bordered)

                    if isGeneratingAI {
                        ProgressView()
                    }

                    Spacer()
                }
                .padding()
                .presentationDetents([.medium])
            }
        }
    }

    private func generateDraft(tone: String) {
        isGeneratingAI = true
        Task {
            do {
                let draft: String
                if let reply = replyTo {
                    draft = try await MailAIService.shared.generateReply(for: reply, context: aiContext)
                } else {
                    draft = try await MailAIService.shared.improveDraft(body.isEmpty ? aiContext : body, tone: tone)
                }

                DispatchQueue.main.async {
                    self.body = draft
                    self.isGeneratingAI = false
                    self.showingAISuggestions = false
                }
            } catch {
                isGeneratingAI = false
            }
        }
    }

    private func send() {
        isSending = true
        Task {
            do {
                let provider = iCloudMailProvider(account: account)
                let message = MailMessage(
                    id: UUID().uuidString,
                    threadId: replyTo?.threadId ?? UUID().uuidString,
                    from: account.email,
                    to: to.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) },
                    cc: [],
                    bcc: [],
                    subject: subject,
                    body: body,
                    htmlBody: nil,
                    date: Date(),
                    isRead: true,
                    isStarred: false,
                    attachments: []
                )
                try await provider.sendMessage(message)
                DispatchQueue.main.async {
                    isSending = false
                    dismiss()
                }
            } catch {
                print("Failed to send email: \(error)")
                DispatchQueue.main.async {
                    isSending = false
                }
            }
        }
    }
}
