import Foundation

// MARK: - GenSlidesScheme

public struct GenSlidesScheme: Codable, Equatable {
    public var meta: SlideMeta
    public var theme: SlideThemeSpec
    public var slides: [SchemeSlide]

    public init(meta: SlideMeta, theme: SlideThemeSpec, slides: [SchemeSlide]) {
        self.meta = meta
        self.theme = theme
        self.slides = slides
    }
}

// MARK: - Meta

public struct SlideMeta: Codable, Equatable {
    public var title: String
    public var description: String
    public var accentColor: String

    public init(title: String, description: String, accentColor: String) {
        self.title = title
        self.description = description
        self.accentColor = accentColor
    }
}

// MARK: - Theme Spec

public struct SlideThemeSpec: Codable, Equatable {
    public var gradient: [String]
    public var font: String
    public var glass: Bool
    public var contrast: String

    public init(gradient: [String], font: String, glass: Bool, contrast: String) {
        self.gradient = gradient
        self.font = font
        self.glass = glass
        self.contrast = contrast
    }
}

// MARK: - Scheme Slide

public struct SchemeSlide: Codable, Equatable, Identifiable {
    public var id: UUID
    public var type: SchemeSlideType
    public var title: String
    public var layout: SchemeSlideLayout
    public var elements: [SchemeSlideElement]

    public init(
        id: UUID = UUID(),
        type: SchemeSlideType,
        title: String,
        layout: SchemeSlideLayout,
        elements: [SchemeSlideElement]
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.layout = layout
        self.elements = elements
    }

    enum CodingKeys: String, CodingKey {
        case id, type, title, layout, elements
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let idStr = try? container.decode(String.self, forKey: .id), let uuid = UUID(uuidString: idStr) {
            id = uuid
        } else if let uuid = try? container.decode(UUID.self, forKey: .id) {
            id = uuid
        } else {
            id = UUID()
        }
        type = try container.decode(SchemeSlideType.self, forKey: .type)
        title = try container.decode(String.self, forKey: .title)
        layout = try container.decode(SchemeSlideLayout.self, forKey: .layout)
        elements = try container.decode([SchemeSlideElement].self, forKey: .elements)
    }
}

// MARK: - Slide Type

public enum SchemeSlideType: String, Codable, CaseIterable {
    case title
    case bullet
    case image
    case twoColumn
    case chart
    case gallery
}

// MARK: - Slide Layout

public struct SchemeSlideLayout: Codable, Equatable {
    public var alignment: String
    public var spacing: Double

    public init(alignment: String = "center", spacing: Double = 16) {
        self.alignment = alignment
        self.spacing = spacing
    }
}

// MARK: - Slide Element

public enum SchemeSlideElement: Codable, Equatable {
    case text(String)
    case bullets([String])
    case image(SchemeImageRef)

    enum CodingKeys: String, CodingKey {
        case text, bullets, image
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let textValue = try? container.decode(String.self, forKey: .text) {
            self = .text(textValue)
        } else if let bulletValues = try? container.decode([String].self, forKey: .bullets) {
            self = .bullets(bulletValues)
        } else if let imageRef = try? container.decode(SchemeImageRef.self, forKey: .image) {
            self = .image(imageRef)
        } else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "Unknown element type")
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let value):
            try container.encode(value, forKey: .text)
        case .bullets(let values):
            try container.encode(values, forKey: .bullets)
        case .image(let ref):
            try container.encode(ref, forKey: .image)
        }
    }
}

// MARK: - Image Reference

public struct SchemeImageRef: Codable, Equatable {
    public var url: String
    public var query: String

    public init(url: String = "", query: String) {
        self.url = url
        self.query = query
    }
}

// MARK: - Validation Error

public enum SlideValidationError: LocalizedError {
    case insufficientSlides(count: Int)
    case emptySlide(index: Int)
    case titleTooLong(slideIndex: Int, title: String)
    case tooManyBullets(slideIndex: Int, count: Int)
    case bulletTooLong(slideIndex: Int, bulletIndex: Int)
    case emptyElement(slideIndex: Int)
    case duplicateSlide(indices: [Int])
    case decodingFailed(underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .insufficientSlides(let count):
            return "Minimum 5 slides required, got \(count)"
        case .emptySlide(let index):
            return "Slide at index \(index) has no elements"
        case .titleTooLong(let index, let title):
            return "Slide \(index) title exceeds 8 words: \"\(title)\""
        case .tooManyBullets(let index, let count):
            return "Slide \(index) has \(count) bullets (max 6)"
        case .bulletTooLong(let index, let bulletIndex):
            return "Slide \(index) bullet \(bulletIndex) exceeds 12 words"
        case .emptyElement(let index):
            return "Slide \(index) contains an empty element"
        case .duplicateSlide(let indices):
            return "Duplicate slides detected at indices: \(indices)"
        case .decodingFailed(let underlying):
            return "JSON decoding failed: \(underlying.localizedDescription)"
        }
    }
}
