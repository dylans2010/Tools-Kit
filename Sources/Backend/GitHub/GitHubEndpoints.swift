import Foundation

/// Defines all supported GitHub API endpoints.
enum GitHubEndpoints {
    private static let baseURL = "https://api.github.com"

    case userRepos
    case searchRepos(query: String)
    case repoDetails(owner: String, repo: String)
    case starred(owner: String, repo: String)
    case branches(owner: String, repo: String)
    case commits(owner: String, repo: String, sha: String?)
    case pullRequests(owner: String, repo: String)
    case prDetails(owner: String, repo: String, number: Int)
    case mergePR(owner: String, repo: String, number: Int)
    case createPR(owner: String, repo: String)
    case updatePR(owner: String, repo: String, number: Int)
    case contents(owner: String, repo: String, path: String, ref: String?)
    case compare(owner: String, repo: String, base: String, head: String)
    case fork(owner: String, repo: String)
    case createRef(owner: String, repo: String)
    case deleteRef(owner: String, repo: String, ref: String)
    case repoIssues(owner: String, repo: String)
    case trending(language: String)
    case user
    case userEvents(username: String)
    case notifications
    case gists
    case gistDetails(id: String)
    case createGist
    case updateGist(id: String)
    case deleteGist(id: String)
    case starGist(id: String)
    case unstarGist(id: String)
    case checkGistStarred(id: String)
    case repoContributors(owner: String, repo: String)
    case repoLanguages(owner: String, repo: String)
    case prComments(owner: String, repo: String, number: Int)
    case prReviews(owner: String, repo: String, number: Int)
    case globalSearch(type: String, query: String)
    case starredRepos
    case userOrgs
    case rateLimit

    var url: URL {
        switch self {
        case .userRepos:
            return URL(string: "\(GitHubEndpoints.baseURL)/user/repos?sort=updated")!
        case .searchRepos(let query):
            let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            return URL(string: "\(GitHubEndpoints.baseURL)/search/repositories?q=\(encodedQuery)")!
        case .repoDetails(let owner, let repo):
            return URL(string: "\(GitHubEndpoints.baseURL)/repos/\(owner)/\(repo)")!
        case .starred(let owner, let repo):
            return URL(string: "\(GitHubEndpoints.baseURL)/user/starred/\(owner)/\(repo)")!
        case .createPR(let owner, let repo):
            return URL(string: "\(GitHubEndpoints.baseURL)/repos/\(owner)/\(repo)/pulls")!
        case .branches(let owner, let repo):
            return URL(string: "\(GitHubEndpoints.baseURL)/repos/\(owner)/\(repo)/branches")!
        case .commits(let owner, let repo, let sha):
            var urlString = "\(GitHubEndpoints.baseURL)/repos/\(owner)/\(repo)/commits"
            if let sha = sha { urlString += "?sha=\(sha)" }
            return URL(string: urlString)!
        case .pullRequests(let owner, let repo):
            return URL(string: "\(GitHubEndpoints.baseURL)/repos/\(owner)/\(repo)/pulls")!
        case .prDetails(let owner, let repo, let number):
            return URL(string: "\(GitHubEndpoints.baseURL)/repos/\(owner)/\(repo)/pulls/\(number)")!
        case .mergePR(let owner, let repo, let number):
            return URL(string: "\(GitHubEndpoints.baseURL)/repos/\(owner)/\(repo)/pulls/\(number)/merge")!
        case .updatePR(let owner, let repo, let number):
            return URL(string: "\(GitHubEndpoints.baseURL)/repos/\(owner)/\(repo)/pulls/\(number)")!
        case .contents(let owner, let repo, let path, let ref):
            var urlString = "\(GitHubEndpoints.baseURL)/repos/\(owner)/\(repo)/contents/\(path)"
            if let ref = ref { urlString += "?ref=\(ref)" }
            return URL(string: urlString)!
        case .compare(let owner, let repo, let base, let head):
            return URL(string: "\(GitHubEndpoints.baseURL)/repos/\(owner)/\(repo)/compare/\(base)...\(head)")!
        case .fork(let owner, let repo):
            return URL(string: "\(GitHubEndpoints.baseURL)/repos/\(owner)/\(repo)/forks")!
        case .createRef(let owner, let repo):
            return URL(string: "\(GitHubEndpoints.baseURL)/repos/\(owner)/\(repo)/git/refs")!
        case .deleteRef(let owner, let repo, let ref):
            let encodedRef = ref.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ref
            return URL(string: "\(GitHubEndpoints.baseURL)/repos/\(owner)/\(repo)/git/refs/\(encodedRef)")!
        case .repoIssues(let owner, let repo):
            return URL(string: "\(GitHubEndpoints.baseURL)/repos/\(owner)/\(repo)/issues?state=all")!
        case .trending(let language):
            return URL(string: "\(GitHubEndpoints.baseURL)/search/repositories?q=language:\(language)&sort=stars&order=desc")!
        case .user:
            return URL(string: "\(GitHubEndpoints.baseURL)/user")!
        case .userEvents(let username):
            return URL(string: "\(GitHubEndpoints.baseURL)/users/\(username)/events")!
        case .notifications:
            return URL(string: "\(GitHubEndpoints.baseURL)/notifications")!
        case .gists:
            return URL(string: "\(GitHubEndpoints.baseURL)/gists")!
        case .gistDetails(let id):
            return URL(string: "\(GitHubEndpoints.baseURL)/gists/\(id)")!
        case .createGist:
            return URL(string: "\(GitHubEndpoints.baseURL)/gists")!
        case .updateGist(let id):
            return URL(string: "\(GitHubEndpoints.baseURL)/gists/\(id)")!
        case .deleteGist(let id):
            return URL(string: "\(GitHubEndpoints.baseURL)/gists/\(id)")!
        case .starGist(let id):
            return URL(string: "\(GitHubEndpoints.baseURL)/gists/\(id)/star")!
        case .unstarGist(let id):
            return URL(string: "\(GitHubEndpoints.baseURL)/gists/\(id)/star")!
        case .checkGistStarred(let id):
            return URL(string: "\(GitHubEndpoints.baseURL)/gists/\(id)/star")!
        case .repoContributors(let owner, let repo):
            return URL(string: "\(GitHubEndpoints.baseURL)/repos/\(owner)/\(repo)/contributors")!
        case .repoLanguages(let owner, let repo):
            return URL(string: "\(GitHubEndpoints.baseURL)/repos/\(owner)/\(repo)/languages")!
        case .prComments(let owner, let repo, let number):
            return URL(string: "\(GitHubEndpoints.baseURL)/repos/\(owner)/\(repo)/pulls/\(number)/comments")!
        case .prReviews(let owner, let repo, let number):
            return URL(string: "\(GitHubEndpoints.baseURL)/repos/\(owner)/\(repo)/pulls/\(number)/reviews")!
        case .globalSearch(let type, let query):
            let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            return URL(string: "\(GitHubEndpoints.baseURL)/search/\(type)?q=\(encodedQuery)")!
        case .starredRepos:
            return URL(string: "\(GitHubEndpoints.baseURL)/user/starred")!
        case .userOrgs:
            return URL(string: "\(GitHubEndpoints.baseURL)/user/orgs")!
        case .rateLimit:
            return URL(string: "\(GitHubEndpoints.baseURL)/rate_limit")!
        }
    }

    var method: String {
        switch self {
        case .userRepos, .searchRepos, .repoDetails, .branches, .commits, .pullRequests, .prDetails, .contents, .compare, .repoIssues, .trending, .user, .userEvents, .notifications, .gists, .gistDetails, .checkGistStarred, .repoContributors, .repoLanguages, .prComments, .prReviews, .globalSearch, .starredRepos, .userOrgs, .rateLimit:
            return "GET"
        case .starred, .starGist:
            return "PUT"
        case .mergePR:
            return "PUT"
        case .updatePR, .updateGist:
            return "PATCH"
        case .fork, .createPR, .createRef, .createGist:
            return "POST"
        case .deleteRef, .deleteGist, .unstarGist:
            return "DELETE"
        }
    }
}
