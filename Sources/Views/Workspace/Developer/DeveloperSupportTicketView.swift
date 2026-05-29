import SwiftUI

struct DeveloperSupportTicketView: View {
    @State private var showingNewTicket = false
    @State private var subject = ""
    @State private var message = ""

    var body: some View {
        List {
            Section("Your Tickets") {
                VStack(spacing: 12) {
                    Image(systemName: "lifepreserver")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("You have no active support tickets.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
            }

            Section("Common Topics") {
                topicLink("Account & Billing")
                topicLink("API Rate Limits")
                topicLink("Marketplace Rejections")
                topicLink("Technical Documentation")
            }
        }
        .navigationTitle("Support")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("New Ticket") { showingNewTicket = true }
            }
        }
        .sheet(isPresented: $showingNewTicket) {
            newTicketSheet
        }
    }

    private var newTicketSheet: some View {
        NavigationStack {
            Form {
                Section("What do you need help with?") {
                    TextField("Subject", text: $subject)
                    Picker("Topic", selection: .constant(0)) {
                        Text("Technical").tag(0)
                        Text("Billing").tag(1)
                        Text("Feedback").tag(2)
                    }
                    VStack(alignment: .leading) {
                        Text("Message").font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $message).frame(height: 150)
                    }
                }
            }
            .navigationTitle("New Ticket")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingNewTicket = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        // Awaiting backend integration
                        showingNewTicket = false
                    }
                    .disabled(subject.isEmpty || message.isEmpty)
                }
            }
        }
    }

    private func topicLink(_ title: String) -> some View {
        NavigationLink(destination: Text(title).navigationTitle(title)) {
            Text(title)
        }
    }
}
