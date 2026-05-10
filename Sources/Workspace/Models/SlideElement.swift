import Foundation

public struct SlideElement: Codable, Identifiable, Equatable {
    public struct ChartData: Codable, Equatable {
        var title: String = ""
        var labels: [String] = []
        var values: [Double] = []

        public init(title: String = "", labels: [String] = [], values: [Double] = []) {
            self.title = title
            self.labels = labels
            self.values = values
        }
    }

    var id: UUID = UUID()
    var kind: ElementKind
    var x: Double = 100
    var y: Double = 100
    var width: Double = 200
    var height: Double = 60
    var zIndex: Int = 0

    // Text
    var text: String = "Text"
    var bullets: [String] = []
    var fontSize: Double = 24
    var fontWeight: String = "regular"
    var textColor: String = "FFFFFF"
    var textAlignment: String = "center"

    // Image
    var imageData: Data?
    var imageURL: URL?
    var caption: String = ""

    // Chart
    var chartData: ChartData?

    // Shape
    var shapeKind: ShapeKind = .rectangle
    var fillColor: String = "3B82F6"
    var strokeColor: String = "FFFFFF"
    var strokeWidth: Double = 0
    var cornerRadius: Double = 8

    public enum ElementKind: String, Codable, CaseIterable {
        case text, bullets, image, chart, shape
    }

    public enum ShapeKind: String, Codable, CaseIterable {
        case rectangle, circle, triangle
        var displayName: String {
            switch self {
            case .rectangle: return "Rectangle"
            case .circle: return "Circle"
            case .triangle: return "Triangle"
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case kind
        case x
        case y
        case width
        case height
        case zIndex
        case text
        case bullets
        case fontSize
        case fontWeight
        case textColor
        case textAlignment
        case imageData
        case imageURL
        case caption
        case chartData
        case shapeKind
        case fillColor
        case strokeColor
        case strokeWidth
        case cornerRadius
    }

    public init(kind: ElementKind) {
        self.kind = kind
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        kind = try container.decodeIfPresent(ElementKind.self, forKey: .kind) ?? .text
        x = try container.decodeIfPresent(Double.self, forKey: .x) ?? 100
        y = try container.decodeIfPresent(Double.self, forKey: .y) ?? 100
        width = try container.decodeIfPresent(Double.self, forKey: .width) ?? 200
        height = try container.decodeIfPresent(Double.self, forKey: .height) ?? 60
        zIndex = try container.decodeIfPresent(Int.self, forKey: .zIndex) ?? 0
        text = try container.decodeIfPresent(String.self, forKey: .text) ?? "Text"
        bullets = try container.decodeIfPresent([String].self, forKey: .bullets) ?? []
        fontSize = try container.decodeIfPresent(Double.self, forKey: .fontSize) ?? 24
        fontWeight = try container.decodeIfPresent(String.self, forKey: .fontWeight) ?? "regular"
        textColor = try container.decodeIfPresent(String.self, forKey: .textColor) ?? "FFFFFF"
        textAlignment = try container.decodeIfPresent(String.self, forKey: .textAlignment) ?? "center"
        imageData = try container.decodeIfPresent(Data.self, forKey: .imageData)
        imageURL = try container.decodeIfPresent(URL.self, forKey: .imageURL)
        caption = try container.decodeIfPresent(String.self, forKey: .caption) ?? ""
        chartData = try container.decodeIfPresent(ChartData.self, forKey: .chartData)
        shapeKind = try container.decodeIfPresent(ShapeKind.self, forKey: .shapeKind) ?? .rectangle
        fillColor = try container.decodeIfPresent(String.self, forKey: .fillColor) ?? "3B82F6"
        strokeColor = try container.decodeIfPresent(String.self, forKey: .strokeColor) ?? "FFFFFF"
        strokeWidth = try container.decodeIfPresent(Double.self, forKey: .strokeWidth) ?? 0
        cornerRadius = try container.decodeIfPresent(Double.self, forKey: .cornerRadius) ?? 8
    }
}
