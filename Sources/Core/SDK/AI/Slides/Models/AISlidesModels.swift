import Foundation

public enum SlideTone: String, CaseIterable, Codable {
    case formal, casual, pitch, educational
}

public enum SlideAudience: String, CaseIterable, Codable {
    case investor, internalTeam, academic
}

public enum SlideVisualDensity: String, CaseIterable, Codable {
    case low, medium, high
}

public struct SlidePhotoAsset: Codable, Equatable, Identifiable {
    public var id: UUID
    public var fileName: String
    public var dataBase64: String

    public init(id: UUID = UUID(), fileName: String, dataBase64: String) {
        self.id = id
        self.fileName = fileName
        self.dataBase64 = dataBase64
    }
}

public struct WhiteboardSlideSection: Codable, Equatable {
    public var title: String
    public var summary: String
    public var nodeIDs: [UUID]

    public init(title: String, summary: String, nodeIDs: [UUID]) {
        self.title = title
        self.summary = summary
        self.nodeIDs = nodeIDs
    }
}

public struct SlideInput: Codable, Equatable {
    public var rawText: String
    public var notes: [String]
    public var whiteboardNodes: [WhiteboardNode]
    public var documents: [String]
    public var uploadedImages: [SlidePhotoAsset]
    public var tone: SlideTone
    public var audience: SlideAudience
    public var slideCount: Int
    public var includeImages: Bool
    public var visualDensity: SlideVisualDensity
    public var sections: [WhiteboardSlideSection]
    public var preferredThemeID: String?
    public var preferredStyleID: String?

    public init(
        rawText: String,
        notes: [String] = [],
        whiteboardNodes: [WhiteboardNode] = [],
        documents: [String] = [],
        uploadedImages: [SlidePhotoAsset] = [],
        tone: SlideTone = .formal,
        audience: SlideAudience = .internalTeam,
        slideCount: Int = 8,
        includeImages: Bool = true,
        visualDensity: SlideVisualDensity = .medium,
        sections: [WhiteboardSlideSection] = [],
        preferredThemeID: String? = nil,
        preferredStyleID: String? = nil
    ) {
        self.rawText = rawText
        self.notes = notes
        self.whiteboardNodes = whiteboardNodes
        self.documents = documents
        self.uploadedImages = uploadedImages
        self.tone = tone
        self.audience = audience
        self.slideCount = max(5, min(15, slideCount))
        self.includeImages = includeImages
        self.visualDensity = visualDensity
        self.sections = sections
        self.preferredThemeID = preferredThemeID
        self.preferredStyleID = preferredStyleID
    }
}

public enum SDKPermission: String, Codable, CaseIterable {
    case readNotes
    case readWhiteboards
    case readDocuments
    case writeSlides
    case accessAIModels
    case networkAccess
}

public struct AISlidesScope: Codable, Equatable {
    public let identifier: String = "sdk.AI.generateSlides"
    public let permissions: [SDKPermission] = [
        .readNotes,
        .readWhiteboards,
        .readDocuments,
        .writeSlides,
        .accessAIModels,
        .networkAccess
    ]

    public init() {}
}

struct SlidePlan: Codable {
    struct PlannedSlide: Codable {
        var index: Int
        var type: String
        var intent: String
        var layout: String
    }

    var title: String
    var theme: String
    var slides: [PlannedSlide]
}

struct VisualPlan: Codable {
    struct VisualSlide: Codable {
        var index: Int
        var imageQuery: String?
        var chartSpec: String?
        var requiresVisual: Bool

        enum CodingKeys: String, CodingKey {
            case index
            case imageQuery = "image_query"
            case chartSpec = "chart_spec"
            case requiresVisual = "requires_visual"
        }
    }

    var slides: [VisualSlide]
}

struct SlideContentPayload: Codable {
    struct ContentSlide: Codable {
        struct ContentElement: Codable {
            var kind: String
            var text: String?
            var bullets: [String]?
            var caption: String?
            var chartTitle: String?
            var chartLabels: [String]?
            var chartValues: [Double]?

            enum CodingKeys: String, CodingKey {
                case kind
                case text
                case bullets
                case caption
                case chartTitle = "chart_title"
                case chartLabels = "chart_labels"
                case chartValues = "chart_values"
            }
        }

        var index: Int
        var title: String
        var type: String
        var layout: String
        var elements: [ContentElement]
        var metadata: [String: String]
    }

    var title: String
    var theme: String
    var slides: [ContentSlide]
}
