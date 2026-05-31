import SwiftUI

struct DeveloperSupportTicketView: View {
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var showingAddTicket = false
    @State private var ticketSubject = ""
    @State private var ticketBody = ""
    @State private var selectedAppID: UUID?
    @State private var ticketPriority = "Medium"
    @State private var ticketCategory = "Technical"

    @State private var tickets: [SupportTicket] = DeveloperPersistentStore.shared.supportTickets

    var body: some View {
        List {
            developerAssistanceSection
            openTicketSection
            ticketsSection
        }
        .navigationTitle("Support")
        .sheet(isPresented: $showingAddTicket) { addTicketSheet }
        .onAppear {
            tickets = DeveloperPersistentStore.shared.supportTickets
            if tickets.isEmpty {
                // Initial data if store is empty
                tickets = [
                    SupportTicket(subject: "API Rate Limit Increase", priority: "High", status: "In Review", appName: "Main App"),
                    SupportTicket(subject: "Marketplace Rejection Appeal", priority: "Medium", status: "Closed", appName: "SDK Extension")
                ]
                DeveloperPersistentStore.shared.saveSupportTickets(tickets)
            }
        }
    }

    private var developerAssistanceSection: some View {
        Section("Developer Assistance") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "lifepreserver.fill").foregroundStyle(.blue)
                    Text("Technical Support").font(.subheadline.bold())
                }
                Text("Our engineers are available to help with integration issues, rate limit adjustments, and platform compliance.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)
        }
    }

    private var openTicketSection: some View {
        Section {
            Button { showingAddTicket = true } label: {
                Label("Open Support Ticket", systemImage: "plus.bubble.fill").font(.subheadline.bold())
            }
        }
    }

    private var ticketsSection: some View {
        Section("Your Tickets") {
            if tickets.isEmpty {
                EmptyStateView(icon: "questionmark.circle", title: "No Open Tickets", message: "Need help? Open a ticket and our team will get back to you within 24 hours.")
            } else {
                ForEach(tickets) { ticket in
                    NavigationLink(destination: TicketDetailView(ticket: ticket)) {
                        SupportTicketRow(ticket: ticket)
                    }
                }
            }
        }
    }

    private var addTicketSheet: some View {
        NavigationStack {
            Form {
                Section("Related Project & Category") {
                    Picker("App", selection: $selectedAppID) {
                        Text("General Inquiry").tag(Optional<UUID>.none)
                        ForEach(appService.apps) { app in
                            Text(app.name).tag(Optional(app.id))
                        }
                    }
                    Picker("Category", selection: $ticketCategory) {
                        ForEach(["Technical", "Billing", "Marketplace", "Legal", "Other"], id: \.self) { Text($0) }
                    }
                }

                Section("Priority") {
                    Picker("Priority", selection: $ticketPriority) {
                        ForEach(["Low", "Medium", "High", "Critical"], id: \.self) { Text($0) }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Issue Details") {
                    TextField("Subject", text: $ticketSubject)
                    TextEditor(text: $ticketBody)
                        .frame(minHeight: 150)
                        .overlay(alignment: .topLeading) {
                            if ticketBody.isEmpty { Text("Describe your issue in detail...").font(.caption).foregroundStyle(.tertiary).padding(.top, 8).padding(.leading, 4) }
                        }
                }
            }
            .navigationTitle("New Support Ticket")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAddTicket = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        let appName = appService.apps.first(where: { $0.id == selectedAppID })?.name ?? "General"
                        let newTicket = SupportTicket(
                            subject: ticketSubject,
                            topic: ticketCategory,
                            priority: ticketPriority,
                            status: "Open",
                            appName: appName,
                            message: ticketBody
                        )
                        tickets.insert(newTicket, at: 0)
                        DeveloperPersistentStore.shared.saveSupportTickets(tickets)
                        showingAddTicket = false
                        ticketSubject = ""
                        ticketBody = ""
                    }
                    .disabled(ticketSubject.isEmpty || ticketBody.isEmpty)
                }
            }
        }
    }
}

private struct SupportTicketRow: View {
    let ticket: SupportTicket

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Circle().fill(priorityColor(ticket.priority)).frame(width: 8, height: 8)
                    Text(ticket.subject).font(.subheadline.bold())
                }
                Text("\(ticket.appName) • \(ticket.topic)").font(.system(size: 9)).foregroundStyle(.secondary)
            }
            Spacer()
            Text(ticket.status.uppercased())
                .font(.system(size: 8, weight: .black))
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(statusBackgroundColor(ticket.status))
                .foregroundStyle(statusForegroundColor(ticket.status))
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }

    private func priorityColor(_ p: String) -> Color {
        switch p {
        case "Critical": return .red
        case "High": return .orange
        case "Medium": return .blue
        default: return .gray
        }
    }

    private func statusBackgroundColor(_ s: String) -> Color {
        s == "Closed" ? Color.secondary.opacity(0.1) : Color.green.opacity(0.1)
    }

    private func statusForegroundColor(_ s: String) -> Color {
        s == "Closed" ? .secondary : Color.green
    }
}

struct TicketDetailView: View {
    @State var ticket: SupportTicket
    @State private var newComment = ""

    var body: some View {
        List {
            Section("Details") {
                LabeledContent("Status", value: ticket.status)
                LabeledContent("Priority", value: ticket.priority)
                LabeledContent("Category", value: ticket.topic)
                LabeledContent("App", value: ticket.appName)
                LabeledContent("Created", value: ticket.createdAt.formatted(date: .abbreviated, time: .shortened))
            }

            Section("Description") {
                Text(ticket.message).font(.subheadline)
            }

            Section("Conversation") {
                if ticket.comments.isEmpty {
                    Text("No comments yet.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(ticket.comments) { comment in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(comment.sender).font(.caption.bold())
                                Spacer()
                                Text(comment.timestamp.formatted(date: .omitted, time: .shortened)).font(.system(size: 8)).foregroundStyle(.tertiary)
                            }
                            Text(comment.content).font(.system(size: 11))
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Section("Add Comment") {
                TextEditor(text: $newComment)
                    .frame(minHeight: 100)
                Button("Post Comment") {
                    postComment()
                }
                .disabled(newComment.isEmpty)
            }

            Section {
                Button(ticket.status == "Closed" ? "Reopen Ticket" : "Close Ticket") {
                    toggleStatus()
                }
                .foregroundStyle(ticket.status == "Closed" ? .blue : .red)
            }
        }
        .navigationTitle(ticket.subject)
    }

    private func postComment() {
        let comment = TicketComment(sender: "Developer (You)", content: newComment)
        var updated = ticket
        updated.comments.append(comment)
        saveTicket(updated)
        newComment = ""
    }

    private func toggleStatus() {
        var updated = ticket
        updated.status = (ticket.status == "Closed" ? "Open" : "Closed")
        saveTicket(updated)
    }

    private func saveTicket(_ updated: SupportTicket) {
        var all = DeveloperPersistentStore.shared.supportTickets
        if let idx = all.firstIndex(where: { $0.id == updated.id }) {
            all[idx] = updated
            DeveloperPersistentStore.shared.saveSupportTickets(all)
            self.ticket = updated
        }
    }
}
