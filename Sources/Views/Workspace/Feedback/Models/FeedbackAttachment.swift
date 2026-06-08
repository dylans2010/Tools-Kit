import Foundation

public struct FeedbackAttachment: Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let type: AttachmentType
    public let url: URL?
    public let localPath: String?

    public enum AttachmentType: String, Codable {
        case image, video, file, screenshot, replay
    }
}
