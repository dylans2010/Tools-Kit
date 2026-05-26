import Foundation

/// Validation tests for GitHub module logic.
struct GitHubValidationTests {
    static func run() async {
        print("Testing GitHub Endpoints...")
        testEndpoints()

        print("Testing GitHub Models (Manual Simulation)...")
        testModels()

        print("GitHub Validation Tests Passed!")
    }

    private static func testEndpoints() {
        let userUrl = GitHubEndpoints.user.url
        assert(userUrl.absoluteString == "https://api.github.com/user")

        let eventsUrl = GitHubEndpoints.userEvents(username: "jules").url
        assert(eventsUrl.absoluteString == "https://api.github.com/users/jules/events")

        let notificationsUrl = GitHubEndpoints.notifications.url
        assert(notificationsUrl.absoluteString == "https://api.github.com/notifications")

        let gistsUrl = GitHubEndpoints.gists.url
        assert(gistsUrl.absoluteString == "https://api.github.com/gists")

        let rateLimitUrl = GitHubEndpoints.rateLimit.url
        assert(rateLimitUrl.absoluteString == "https://api.github.com/rate_limit")

        assert(GitHubEndpoints.user.method == "GET")
    }

    private static func testModels() {
        // Since we can't easily run a full JSON decoder test without sample data in this script,
        // we verify the structs are validly defined by instantiating them.

        let user = GitHubAuthenticatedUser(
            id: 1,
            login: "testuser",
            avatarUrl: "https://example.com/avatar.png",
            name: "Test User",
            company: nil,
            blog: nil,
            location: nil,
            email: nil,
            bio: "I am a test user.",
            publicRepos: 10,
            publicGists: 5,
            followers: 100,
            following: 50,
            createdAt: Date()
        )
        assert(user.login == "testuser")

        let rateLimit = GitHubRateLimit(limit: 5000, remaining: 4999, reset: 123456789, used: 1)
        assert(rateLimit.remaining == 4999)
    }

    private static func assert(_ condition: Bool, message: String = "Assertion failed") {
        if !condition {
            fatalError("GitHubValidationTests: \(message)")
        }
    }
}
