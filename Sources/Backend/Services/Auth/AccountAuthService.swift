import Foundation
import Appwrite

enum AuthServiceError: LocalizedError {
    case unsupportedOAuthProvider(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedOAuthProvider(let provider):
            return "Unsupported OAuth provider: \(provider)"
        }
    }
}

@MainActor
final class AccountAuthService: ObservableObject {
    static let shared = AccountAuthService()

    @Published var isBusy = false
    @Published var lastErrorMessage: String?

    private init() {}

    func restoreSession() async -> Bool {
        do {
            _ = try await AppwriteService.account.get()
            return true
        } catch {
            return false
        }
    }

    func signIn(email: String, password: String) async throws {
        isBusy = true
        lastErrorMessage = nil
        defer { isBusy = false }

        do {
            _ = try await AppwriteService.account.createEmailPasswordSession(email: email, password: password)
            await UserDataManager.shared.syncAfterLogin()
        } catch {
            lastErrorMessage = error.localizedDescription
            throw error
        }
    }

    func createAccount(name: String, email: String, password: String) async throws {
        isBusy = true
        lastErrorMessage = nil
        defer { isBusy = false }

        do {
            let createdUser = try await AppwriteService.account.create(
                userId: "unique()",
                email: email,
                password: password,
                name: name.isEmpty ? nil : name
            )

            _ = try await AppwriteService.account.createEmailPasswordSession(email: email, password: password)

            do {
                try await AuthDatabaseService.shared.upsertUserProfile(
                    userId: createdUser.id,
                    email: email,
                    name: name,
                    provider: "email"
                )
            } catch {
                // Keep auth successful even if profile persistence is misconfigured.
                print("Auth profile save failed: \(error.localizedDescription)")
            }

            await UserDataManager.shared.syncAfterLogin()
        } catch {
            lastErrorMessage = error.localizedDescription
            throw error
        }
    }

    func signInWithOAuth(provider: String) async throws {
        isBusy = true
        lastErrorMessage = nil
        defer { isBusy = false }

        do {
            switch provider.lowercased() {
            case "google":
                _ = try await AppwriteService.account.createOAuth2Session(provider: .google)
            case "github":
                _ = try await AppwriteService.account.createOAuth2Session(provider: .github)
            case "discord":
                _ = try await AppwriteService.account.createOAuth2Session(provider: .discord)
            default:
                throw AuthServiceError.unsupportedOAuthProvider(provider)
            }

            do {
                let currentUser = try await AppwriteService.account.get()
                try await AuthDatabaseService.shared.upsertUserProfile(
                    userId: currentUser.id,
                    email: currentUser.email,
                    name: currentUser.name,
                    provider: provider.lowercased()
                )

                // Sync GitHub Token if provider is GitHub
                if provider.lowercased() == "github" {
                    await syncGitHubToken()
                }
            } catch {
                print("OAuth profile save failed: \(error.localizedDescription)")
            }

            await UserDataManager.shared.syncAfterLogin()
        } catch {
            lastErrorMessage = error.localizedDescription
            throw error
        }
    }

    /// Attempts to retrieve the GitHub access token from the AppWrite session and save it.
    func syncGitHubToken() async {
        do {
            let session = try await AppwriteService.account.getSession(sessionId: "current")
            if !session.providerAccessToken.isEmpty {
                GitHubAuthManager.shared.saveToken(session.providerAccessToken)
                print("Successfully synced GitHub token from OAuth session.")
            }
        } catch {
            print("Failed to sync GitHub token from session: \(error.localizedDescription)")
        }
    }

    func signOut() async throws {
        isBusy = true
        lastErrorMessage = nil
        defer { isBusy = false }

        do {
            _ = try await AppwriteService.account.deleteSession(sessionId: "current")
        } catch {
            lastErrorMessage = error.localizedDescription
            throw error
        }
    }
}
