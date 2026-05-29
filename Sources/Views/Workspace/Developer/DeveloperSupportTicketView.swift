import SwiftUI

struct DeveloperSupportTicketView: View {
    @State private var showingNewTicket = false

    var body: some View {
        List {
            Section("Your Tickets") {
                Text("You have no active support tickets.").font(.caption).foregroundStyle(.secondary)
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
            Button("New Ticket") { showingNewTicket = true }
        }
        .sheet(isPresented: $showingNewTicket) {
            NavigationStack {
                Form {
                    Section("What do you need help with?") {
                        TextField("Subject", text: .constant(""))
                        Picker("Topic", selection: .constant(0)) {
                            Text("Technical").tag(0)
                            Text("Billing").tag(1)
                            Text("Feedback").tag(2)
                        }
                        TextEditor(text: .constant("")).frame(height: 150)
                    }
                }
                .navigationTitle("New Ticket")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingNewTicket = false } }
                    ToolbarItem(placement: .confirmationAction) { Button("Submit") { showingNewTicket = false } }
                }
            }
        }
    }

    private func topicLink(_ title: String) -> some View {
        NavigationLink(destination: Text(title)) {
            Text(title)
        }
    }
}
