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
        }
    }

    var method: String {
        switch self {
        case .userRepos, .searchRepos, .repoDetails, .branches, .commits, .pullRequests, .prDetails, .contents, .compare, .repoIssues, .trending:
            return "GET"
        case .starred:
            return "PUT"
        case .mergePR:
            return "PUT"
        case .updatePR:
            return "PATCH"
        case .fork, .createPR, .createRef:
            return "POST"
        case .deleteRef:
            return "DELETE"
        }
    }
}
