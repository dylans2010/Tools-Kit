import Foundation

struct HFModel: Identifiable, Codable, Hashable {
    let id: String
    let author: String?
    let lastModified: Date?
    let likes: Int?
    let downloads: Int?
    let tags: [String]?
    let siblings: [HFSibling]?

    struct HFSibling: Codable, Hashable {
        let rfilename: String
    }

    var name: String {
        id.components(separatedBy: "/").last ?? id
    }

    var url: URL? {
        URL(string: "https://huggingface.co/\(id)")
    }
}

struct HFSearchResponse: Codable {
    let models: [HFModel]
}
