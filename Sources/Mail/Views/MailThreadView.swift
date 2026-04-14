import SwiftUI

struct MailThreadView: View {
    let account: MailAccount
    @State var thread: MailThread
    @State private var showingReply = false
    @State private var summary: String?
    @State private var isSummarizing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(thread.subject)
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)

                if let summary = summary {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("AI Summary", systemImage: "sparkles")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                        Text(summary)
                            .font(.subheadline)
                    }
                    .padding()
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                ForEach(thread.messages) { message in
                    MessageView(message: message)
                }
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: summarize) {
                    Image(systemName: isSummarizing ? "ellipsis" : "sparkles")
                }
                .disabled(isSummarizing)

                Button(action: { showingReply = true }) {
                    Image(systemName: "arrowshape.turn.up.left")
                }
            }
        }
        .sheet(isPresented: $showingReply) {
            EmailComposingView(account: account, replyTo: thread.messages.last)
        }
    }

    private func summarize() {
        isSummarizing = true
        Task {
            do {
                let result = try await MailAIService.shared.summarizeThread(thread)
                DispatchQueue.main.async {
                    self.summary = result
                    self.isSummarizing = false
                }
            } catch {
                isSummarizing = false
            }
        }
    }
}

struct MessageView: View {
    let message: MailMessage
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(message.from)
                            .font(.headline)
                        Text("to \(message.to.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(message.date, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()
                MailContentRenderer(htmlContent: message.htmlBody ?? "", plainTextContent: message.body)
                    .frame(minHeight: 200)
            } else {
                Text(message.body)
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}
