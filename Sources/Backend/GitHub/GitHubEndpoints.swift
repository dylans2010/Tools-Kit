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
    case contents(owner: String, repo: String, path: String, ref: String?)
    case compare(owner: String, repo: String, base: String, head: String)
    case fork(owner: String, repo: String)

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
        case .contents(let owner, let repo, let path, let ref):
            var urlString = "\(GitHubEndpoints.baseURL)/repos/\(owner)/\(repo)/contents/\(path)"
            if let ref = ref { urlString += "?ref=\(ref)" }
            return URL(string: urlString)!
        case .compare(let owner, let repo, let base, let head):
            return URL(string: "\(GitHubEndpoints.baseURL)/repos/\(owner)/\(repo)/compare/\(base)...\(head)")!
        case .fork(let owner, let repo):
            return URL(string: "\(GitHubEndpoints.baseURL)/repos/\(owner)/\(repo)/forks")!
        }
    }

    var method: String {
        switch self {
        case .userRepos, .searchRepos, .repoDetails, .branches, .commits, .pullRequests, .prDetails, .contents, .compare:
            return "GET"
        case .starred:
            return "PUT"
        case .mergePR:
            return "PUT"
        case .fork, .createPR:
            return "POST"
        }
    }
}
