import SwiftUI

struct DeveloperSupportTicketView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared
    @State private var showingNewTicket = false
    @State private var subject = ""
    @State private var message = ""
    @State private var selectedTopic = "Technical Integration"

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
