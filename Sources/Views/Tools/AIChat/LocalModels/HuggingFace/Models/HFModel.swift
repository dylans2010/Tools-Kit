import Foundation

struct HFFile: Codable, Hashable {
    let rfilename: String
}

struct HFModel: Identifiable, Codable, Hashable {
    let id: String
    let author: String?
    let lastModified: Date?
    let likes: Int?
    let downloads: Int?
    let tags: [String]?
    let siblings: [HFFile]?

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
