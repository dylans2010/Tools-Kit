import Foundation

struct RadioStation: Identifiable, Codable, Equatable, Sendable {
    var id: String { stationuuid }

    let stationuuid: String
    let name: String
    let url_resolved: String
    let favicon: String
    let tags: String
    let country: String
    let language: String
    let bitrate: Int
    let codec: String

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        stationuuid = (try? container.decode(String.self, forKey: .stationuuid)) ?? UUID().uuidString
        name = ((try? container.decode(String.self, forKey: .name)) ?? "Unknown Station")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        url_resolved = (try? container.decode(String.self, forKey: .url_resolved)) ?? ""
        favicon = (try? container.decode(String.self, forKey: .favicon)) ?? ""
        tags = (try? container.decode(String.self, forKey: .tags)) ?? ""
        country = (try? container.decode(String.self, forKey: .country)) ?? ""
        language = (try? container.decode(String.self, forKey: .language)) ?? ""
        bitrate = (try? container.decode(Int.self, forKey: .bitrate)) ?? 0
        codec = (try? container.decode(String.self, forKey: .codec)) ?? ""
    }

    private enum CodingKeys: String, CodingKey, Sendable {
        case stationuuid, name, url_resolved, favicon, tags, country, language, bitrate, codec
    }

    var tagList: [String] {
        tags.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(5)
            .map { $0 }
    }

    var bitrateLabel: String {
        bitrate > 0 ? "\(bitrate) kbps" : ""
    }

    var resolvedURL: URL? {
        url_resolved.isEmpty ? nil : URL(string: url_resolved)
    }

    var faviconURL: URL? {
        favicon.isEmpty ? nil : URL(string: favicon)
    }
}
