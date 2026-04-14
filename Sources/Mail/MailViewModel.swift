import SwiftUI
import Combine

@MainActor
class MailViewModel: ObservableObject {
    @Published var emails: [EmailMessage] = []
    @Published var selectedEmail: EmailMessage? = nil
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var searchQuery = ""

    private let imap = IMAPClient()
    private var cancellables = Set<AnyCancellable>()

    var filteredEmails: [EmailMessage] {
        if searchQuery.isEmpty { return emails }
        return emails.filter {
            $0.subject.localizedCaseInsensitiveContains(searchQuery) ||
            $0.sender.localizedCaseInsensitiveContains(searchQuery)
        }
    }

    var isAuthenticated: Bool {
        imap.isAuthenticated
    }

    init() {
        imap.$emails.assign(to: &$emails)
        imap.$isLoading.assign(to: &$isLoading)
        imap.$errorMessage.assign(to: &$errorMessage)
    }

    func signIn(email: String, appPassword: String) {
        imap.connect(username: email, appSpecificPassword: appPassword)
    }

    func loadBody(for email: EmailMessage) {
        guard email.body == nil else { return }
        imap.fetchBody(for: email.uid) { [weak self] body in
            guard let self,
                  let idx = self.emails.firstIndex(where: { $0.uid == email.uid }) else { return }
            self.emails[idx].body = body
            if self.selectedEmail?.uid == email.uid {
                self.selectedEmail?.body = body
            }
        }
    }

    func refresh() {
        // Re-fetch inbox (only if already authenticated)
        guard imap.isAuthenticated else { return }
        imap.fetchEmailList()
    }

    func signOut() {
        imap.disconnect()
        emails = []
    }
}
