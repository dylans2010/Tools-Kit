import SwiftUI

struct DeveloperSupportTicketView: View {
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var showingAddTicket = false
    @State private var ticketSubject = ""
    @State private var ticketBody = ""
    @State private var selectedAppID: UUID?

    @State private var tickets: [SupportTicket] = [
        SupportTicket(subject: "API Rate Limit Increase", status: "In Review", appName: "Main App"),
        SupportTicket(subject: "Marketplace Rejection Appeal", status: "Closed", appName: "SDK Extension")
    ]

    var body: some View {
        List {
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

            Section {
                Button { showingAddTicket = true } label: {
                    Label("Open Support Ticket", systemImage: "plus.bubble.fill").font(.subheadline.bold())
                }
            }

            Section("Your Tickets") {
                if tickets.isEmpty {
                    EmptyStateView(icon: "questionmark.circle", title: "No Open Tickets", message: "Need help? Open a ticket and our team will get back to you within 24 hours.")
                } else {
                    ForEach(tickets) { ticket in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(ticket.subject).font(.subheadline.bold())
                                Text(ticket.appName).font(.system(size: 9)).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(ticket.status.uppercased())
                                .font(.system(size: 8, weight: .black))
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(ticket.status == "Closed" ? Color.secondary.opacity(0.1) : Color.green.opacity(0.1))
                                .foregroundStyle(ticket.status == "Closed" ? .secondary : .green)
                                .clipShape(Capsule())
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Support")
        .sheet(isPresented: $showingAddTicket) { addTicketSheet }
    }

    private var addTicketSheet: some View {
        NavigationStack {
            Form {
                Section("Related Project") {
                    Picker("App", selection: $selectedAppID) {
                        Text("General Inquiry").tag(Optional<UUID>.none)
                        ForEach(appService.apps) { app in
                            Text(app.name).tag(Optional(app.id))
                        }
                    }
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
                        let newTicket = SupportTicket(subject: ticketSubject, status: "Open", appName: appName)
                        tickets.insert(newTicket, at: 0)
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

