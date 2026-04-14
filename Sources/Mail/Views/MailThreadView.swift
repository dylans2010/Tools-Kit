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
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.purple)
                            Text("AI Thread Summary")
                                .font(.headline)
                                .foregroundColor(.purple)
                        }

                        Text(summary)
                            .font(.subheadline)
                            .lineSpacing(4)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.purple.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                            )
                    )
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
                        .foregroundStyle(
                            LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
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
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}
