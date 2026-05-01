import Foundation
enum PRStatus: String, Codable { case open, merged, closed, draft }
struct PullRequest: Identifiable, Codable {
    let id: UUID; let spaceID: UUID; var title: String; var status: PRStatus; var author: String
}