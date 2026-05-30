import SwiftUI

struct DeveloperSupportTicketView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared
    @State private var showingNewTicket = false
    @State private var subject = ""
    @State private var message = ""
    @State private var selectedTopic = "Technical Integration"
    @State private var selectedTicketID: UUID?

    var body: some View {
        List {
            Section("Your Support Activity") {
                if store.supportTickets.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "lifepreserver")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No active support requests found.")
                            .font(.subheadline.bold())
                        Text("Need help? Open a new ticket or browse our knowledge base.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 30)
                    .frame(maxWidth: .infinity)
                } else {
                    ForEach(store.supportTickets) { ticket in
                        Button {
                            selectedTicketID = ticket.id
                        } label: {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(ticket.subject).font(.subheadline.bold())
                                    Spacer()
                                    Text(ticket.status).font(.caption2.bold())
                                        .padding(.horizontal, 6).padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.1), in: Capsule())
                                }
                                Text(ticket.createdAt.formatted()).font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Section("Browse Documentation & FAQs") {
                topicLink("Account & Authentication", icon: "person.badge.key")
                topicLink("API Usage & Rate Limits", icon: "bolt.fill")
                topicLink("Marketplace Guidelines", icon: "storefront.fill")
                topicLink("Technical SDK Reference", icon: "book.fill")
            }
        }
        .navigationTitle("Developer Support")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Open Ticket") { showingNewTicket = true }
            }
        }
        .sheet(isPresented: $showingNewTicket) {
            newTicketSheet
        }
        .sheet(item: Binding(get: { selectedTicketID.map { IdentifiableUUID(id: $0) } }, set: { selectedTicketID = $0?.id })) { item in
            ticketDetailSheet(id: item.id)
        }
    }

    private func ticketDetailSheet(id: UUID) -> some View {
        let ticket = store.supportTickets.first { $0.id == id }
        return NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(ticket?.subject ?? "").font(.title3.bold())
                        Text(ticket?.topic ?? "").font(.caption).foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Conversation History").font(.headline)
                        VStack(alignment: .leading, spacing: 12) {
                            messageBubble(text: ticket?.message ?? "", isUser: true, date: ticket?.createdAt ?? Date())
                            messageBubble(text: "Thank you for contacting support. Our team will review your request and get back to you shortly.", isUser: false, date: Date())
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Ticket Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { selectedTicketID = nil } }
            }
        }
    }

    private func messageBubble(text: String, isUser: Bool, date: Date) -> some View {
        HStack {
            if isUser { Spacer() }
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(text)
                    .font(.subheadline)
                    .padding()
                    .background(isUser ? Color.accentColor : Color.secondary.opacity(0.1))
                    .foregroundStyle(isUser ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                Text(date.formatted()).font(.system(size: 8)).foregroundStyle(.tertiary)
            }
            if !isUser { Spacer() }
        }
    }

    private var newTicketSheet: some View {
        NavigationStack {
            Form {
                Section("Request Details") {
                    TextField("Summarize the issue", text: $subject)
                    Picker("Topic Category", selection: $selectedTopic) {
                        Text("Technical Integration").tag("Technical Integration")
                        Text("Billing & Account").tag("Billing & Account")
                        Text("Policy & Compliance").tag("Policy & Compliance")
                        Text("General Feedback").tag("General Feedback")
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Detailed Description").font(.caption.bold()).foregroundStyle(.secondary)
                        TextEditor(text: $message)
                            .frame(height: 150)
                            .padding(4)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                    }
                }
            }
            .navigationTitle("New Support Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingNewTicket = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit Ticket") {
                        let ticket = SupportTicket(subject: subject, topic: selectedTopic, message: message)
                        var current = store.supportTickets
                        current.insert(ticket, at: 0)
                        store.saveSupportTickets(current)
                        subject = ""
                        message = ""
                        showingNewTicket = false
                    }
                    .disabled(subject.count < 5 || message.count < 10)
                }
            }
        }
    }

    private func topicLink(_ title: String, icon: String) -> some View {
        NavigationLink(destination: Text(title).navigationTitle(title)) {
            Label(title, systemImage: icon)
        }
    }
}
