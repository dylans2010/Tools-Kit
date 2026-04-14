import Foundation

struct MailFolder: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let type: FolderType

    enum FolderType: String, Codable {
        case inbox
        case sent
        case drafts
        case starred
        case trash
        case custom
    }

    static let inbox = MailFolder(id: "INBOX", name: "Inbox", type: .inbox)
    static let sent = MailFolder(id: "SENT", name: "Sent", type: .sent)
    static let drafts = MailFolder(id: "DRAFTS", name: "Drafts", type: .drafts)
    static let starred = MailFolder(id: "STARRED", name: "Starred", type: .starred)
    static let trash = MailFolder(id: "TRASH", name: "Trash", type: .trash)
}
