import SwiftUI

struct ActivityView: View {
    @StateObject private var storage = MailStorageService.shared
    @StateObject private var mailStore = MailStore.shared

    @State private var selectedEmail: MailMessage?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        attachmentsHub

                        recentActivitySection

                        highlightsSection

                        followUpsSection

                        Spacer(minLength: 100)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Activity")
            .navigationDestination(item: $selectedEmail) { message in
                if let account = mailStore.activeAccount {
                    InboxDetailView(account: account, message: message)
                }
            }
        }
    }

    // MARK: - Sections

    private var attachmentsHub: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Attachments")
                .font(.headline)
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(recentAttachments, id: \.1.id) { (thread, attachment) in
                        Button {
                            selectedEmail = thread.messages.last
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.secondarySystemBackground))
                                        .frame(width: 120, height: 80)

                                    Image(systemName: attachmentIcon(attachment.contentType))
                                        .font(.title)
                                        .foregroundColor(.accentColor)
                                }

                                Text(attachment.fileName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                    .frame(width: 120, alignment: .leading)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
                .padding(.horizontal, 16)

            VStack(spacing: 10) {
                ForEach(recentThreads.prefix(5)) { thread in
                    if let message = thread.messages.last {
                        activityRow(email: message)
                            .onTapGesture {
                                selectedEmail = message
                            }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var highlightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Smart Highlights")
                .font(.headline)
                .padding(.horizontal, 16)

            VStack(spacing: 10) {
                ForEach(highlightedThreads.prefix(5)) { thread in
                    if let message = thread.messages.last {
                        activityRow(email: message)
                            .onTapGesture {
                                selectedEmail = message
                            }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var followUpsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Unread + Follow-ups")
                .font(.headline)
                .padding(.horizontal, 16)

            VStack(spacing: 10) {
                ForEach(followUpThreads.prefix(5)) { thread in
                    if let message = thread.messages.last {
                        activityRow(email: message)
                            .onTapGesture {
                                selectedEmail = message
                            }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Row UI

    private func activityRow(email: MailMessage) -> some View {
        HStack(spacing: 12) {
            avatarView(email: email)

            VStack(alignment: .leading, spacing: 3) {
                Text(senderName(from: email.from))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(email.subject)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(timeString(for: email.date))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func avatarView(email: MailMessage) -> some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.2))
                .frame(width: 40, height: 40)

            Text(String(senderName(from: email.from).prefix(1).uppercased()))
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.accentColor)
        }
    }

    // MARK: - Data Helpers

    private var recentThreads: [MailThread] {
        storage.threads.sorted { $0.lastMessageDate > $1.lastMessageDate }
    }

    private var highlightedThreads: [MailThread] {
        storage.threads.filter { thread in
            let msg = thread.messages.last
            let hasAttachments = !(msg?.attachments.isEmpty ?? true)
            let content = ((msg?.subject ?? "") + (msg?.body ?? "")).lowercased()
            let isCalendar = content.contains("meeting") || content.contains("schedule")
            let isFinancial = content.contains("invoice") || content.contains("payment")
            return hasAttachments || isCalendar || isFinancial
        }
    }

    private var followUpThreads: [MailThread] {
        storage.threads.filter { thread in
            let isUnread = !thread.isRead
            let lastMsgFromMe = thread.messages.last?.from.lowercased().contains(mailStore.activeAccount?.emailAddress.lowercased() ?? "____") ?? false
            return isUnread || !lastMsgFromMe
        }
    }

    private var recentAttachments: [(MailThread, MailMessage.MailAttachment)] {
        var all: [(MailThread, MailMessage.MailAttachment)] = []
        for thread in storage.threads {
            for msg in thread.messages {
                for att in msg.attachments {
                    all.append((thread, att))
                }
            }
        }
        return all.sorted { $0.0.lastMessageDate > $1.0.lastMessageDate }.prefix(10).map { $0 }
    }

    private func senderName(from value: String) -> String {
        if let range = value.range(of: "<") {
            return String(value[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return value
    }

    private func timeString(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func attachmentIcon(_ contentType: String) -> String {
        if contentType.hasPrefix("image/") { return "photo" }
        if contentType.contains("pdf") { return "doc.richtext" }
        return "doc.fill"
    }
}
