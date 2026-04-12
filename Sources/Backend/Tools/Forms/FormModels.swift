import Foundation

enum FormQuestionType: String, Codable, CaseIterable, Identifiable {
    case textInput
    case multipleChoice
    case ratingScale
    case slider
    case dropdown
    case imageUpload
    case dragDrop

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .textInput: return "Text Input"
        case .multipleChoice: return "Multiple Choice"
        case .ratingScale: return "Rating Scale"
        case .slider: return "Slider"
        case .dropdown: return "Dropdown"
        case .imageUpload: return "Image Upload"
        case .dragDrop: return "Drag & Drop"
        }
    }
}

struct FormQuestion: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var type: FormQuestionType
    var options: [String] = []
    var required: Bool = false
}

struct FormManifest: Codable, Hashable {
    var createdBy: String
    var createdAt: Date
    var appVersion: String
    var privacyNote: String
}

struct FormDocument: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var description: String
    var questions: [FormQuestion]
    var accentHexColor: String
    var backgroundHexColor: String
    var manifest: FormManifest
}

struct FilledOutFormDocument: Codable, Hashable {
    var formID: UUID
    var formName: String
    var answeredAt: Date
    var answers: [UUID: String]
    var responderName: String
}
