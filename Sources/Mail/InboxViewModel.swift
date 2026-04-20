import SwiftUI
import Combine

@MainActor
final class InboxViewModel: ObservableObject {
    @Published var localThreads: [MailThread] = []
    @Published var isInitialLoading = true
    @Published var errorMessage: String?

    private let storage = MailStorageService.shared
    private var account: MailAccount?
    private var folder: MailFolder = .inbox
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Observe MailSyncService for errors if needed, or other sync status
        MailSyncService.shared.$lastError
            .receive(on: RunLoop.main)
            .assign(to: &$errorMessage)
    }

    func configure(account: MailAccount, folder: MailFolder) {
        self.account = account
        self.folder = folder
    }

    func loadCachedThenRefreshIfNeeded() async {
        guard let account else {
            isInitialLoading = false
            return
        }

        let key = "\(account.id)_\(folder.id)"
        let cached = storage.loadThreads(for: key)
        localThreads = cached

        if cached.isEmpty {
            isInitialLoading = true
            await refresh(fetchFromServer: true)
            isInitialLoading = false
        } else {
            isInitialLoading = false
        }
    }

    func refresh(fetchFromServer: Bool) async {
        guard let account else { return }

        if fetchFromServer {
            InternalLogger.shared.log("InboxViewModel: Triggering fetch for \(account.emailAddress)", level: .info)
            await MailSyncService.shared.fetchThreads(account: account, folder: folder)
        }

        let key = "\(account.id)_\(folder.id)"
        localThreads = storage.loadThreads(for: key)

        InternalLogger.shared.log("InboxViewModel: Updated with \(localThreads.count) threads", level: .info)
    }
}
