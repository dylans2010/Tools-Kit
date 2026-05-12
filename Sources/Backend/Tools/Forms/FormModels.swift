import Foundation

enum FormQuestionType: String, Codable, CaseIterable, Identifiable, Sendable {
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
    var icon: String {
        switch self {
        case .textInput:      return "text.cursor"
        case .multipleChoice: return "checklist"
        case .ratingScale:    return "star.leadinghalf.filled"
        case .slider:         return "slider.horizontal.3"
        case .dropdown:       return "chevron.down.circle"
        case .imageUpload:    return "photo.badge.plus"
        case .dragDrop:       return "arrow.up.arrow.down"
        }
    }
}

struct FormQuestion: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID()
    /// A short creator-assigned name/label for this question (e.g. "satisfaction_rating").
    var questionName: String = ""
    var title: String
    var type: FormQuestionType
    /// Named elements for this question (choice labels, drag-drop items, dropdown entries, etc.)
    var options: [String] = []
    var required: Bool = false
}

struct FormManifest: Codable, Hashable, Sendable {
    var createdBy: String
    var createdAt: Date
    var lastEditedAt: Date
    var formVersion: String
    var manifestSchemaVersion: String
    var appVersion: String
    var buildNumber: String
    var bundleIdentifier: String
    var platform: String
    var localeIdentifier: String
    var timeZoneIdentifier: String
    var questionCount: Int
    var requiredQuestionCount: Int
    var supportsAttachments: Bool
    var templateName: String?
    var privacyNote: String
    var exportNote: String
    var tags: [String]

    init(
        createdBy: String,
        createdAt: Date,
        lastEditedAt: Date = Date(),
        formVersion: String = "1.0",
        manifestSchemaVersion: String = "2.0",
        appVersion: String,
        buildNumber: String = "1",
        bundleIdentifier: String = "com.dylans2010.ToolsKit",
        platform: String = "iOS",
        localeIdentifier: String = Locale.current.identifier,
        timeZoneIdentifier: String = TimeZone.current.identifier,
        questionCount: Int = 0,
        requiredQuestionCount: Int = 0,
        supportsAttachments: Bool = false,
        templateName: String? = nil,
        privacyNote: String,
        exportNote: String = "Review form data before sharing outside your trusted workspace.",
        tags: [String] = []
    ) {
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.lastEditedAt = lastEditedAt
        self.formVersion = formVersion
        self.manifestSchemaVersion = manifestSchemaVersion
        self.appVersion = appVersion
        self.buildNumber = buildNumber
        self.bundleIdentifier = bundleIdentifier
        self.platform = platform
        self.localeIdentifier = localeIdentifier
        self.timeZoneIdentifier = timeZoneIdentifier
        self.questionCount = questionCount
        self.requiredQuestionCount = requiredQuestionCount
        self.supportsAttachments = supportsAttachments
        self.templateName = templateName
        self.privacyNote = privacyNote
        self.exportNote = exportNote
        self.tags = tags
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let now = Date()
        createdBy = try container.decodeIfPresent(String.self, forKey: .createdBy) ?? "Unknown"
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? now
        lastEditedAt = try container.decodeIfPresent(Date.self, forKey: .lastEditedAt) ?? createdAt
        formVersion = try container.decodeIfPresent(String.self, forKey: .formVersion) ?? "1.0"
        manifestSchemaVersion = try container.decodeIfPresent(String.self, forKey: .manifestSchemaVersion) ?? "1.0"
        appVersion = try container.decodeIfPresent(String.self, forKey: .appVersion) ?? "1.0"
        buildNumber = try container.decodeIfPresent(String.self, forKey: .buildNumber) ?? "1"
        bundleIdentifier = try container.decodeIfPresent(String.self, forKey: .bundleIdentifier) ?? "com.dylans2010.ToolsKit"
        platform = try container.decodeIfPresent(String.self, forKey: .platform) ?? "iOS"
        localeIdentifier = try container.decodeIfPresent(String.self, forKey: .localeIdentifier) ?? Locale.current.identifier
        timeZoneIdentifier = try container.decodeIfPresent(String.self, forKey: .timeZoneIdentifier) ?? TimeZone.current.identifier
        questionCount = try container.decodeIfPresent(Int.self, forKey: .questionCount) ?? 0
        requiredQuestionCount = try container.decodeIfPresent(Int.self, forKey: .requiredQuestionCount) ?? 0
        supportsAttachments = try container.decodeIfPresent(Bool.self, forKey: .supportsAttachments) ?? false
        templateName = try container.decodeIfPresent(String.self, forKey: .templateName)
        privacyNote = try container.decodeIfPresent(String.self, forKey: .privacyNote) ?? "Review manifest before sharing."
        exportNote = try container.decodeIfPresent(String.self, forKey: .exportNote) ?? "Review form data before sharing outside your trusted workspace."
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
    }

    static func compose(
        creatorName: String,
        questions: [FormQuestion],
        privacyNote: String,
        templateName: String? = nil,
        tags: [String] = []
    ) -> FormManifest {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        let bundleID = Bundle.main.bundleIdentifier ?? "com.dylans2010.ToolsKit"
        let questionCount = questions.count
        let requiredCount = questions.filter(\.required).count
        let supportsAttachments = questions.contains { $0.type == .imageUpload }

        return FormManifest(
            createdBy: creatorName.isEmpty ? "Unknown" : creatorName,
            createdAt: Date(),
            lastEditedAt: Date(),
            formVersion: "1.0",
            manifestSchemaVersion: "2.0",
            appVersion: version,
            buildNumber: build,
            bundleIdentifier: bundleID,
            platform: "iOS",
            localeIdentifier: Locale.current.identifier,
            timeZoneIdentifier: TimeZone.current.identifier,
            questionCount: questionCount,
            requiredQuestionCount: requiredCount,
            supportsAttachments: supportsAttachments,
            templateName: templateName,
            privacyNote: privacyNote,
            tags: tags
        )
    }
}

struct FormDocument: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID()
    var name: String
    var description: String
    var questions: [FormQuestion]
    var accentHexColor: String
    var backgroundHexColor: String
    var manifest: FormManifest
    var ownerAccessKey: String

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        questions: [FormQuestion],
        accentHexColor: String,
        backgroundHexColor: String,
        manifest: FormManifest,
        ownerAccessKey: String = UUID().uuidString
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.questions = questions
        self.accentHexColor = accentHexColor
        self.backgroundHexColor = backgroundHexColor
        self.manifest = manifest
        self.ownerAccessKey = ownerAccessKey
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Untitled Form"
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        questions = try container.decodeIfPresent([FormQuestion].self, forKey: .questions) ?? []
        accentHexColor = try container.decodeIfPresent(String.self, forKey: .accentHexColor) ?? "007AFF"
        backgroundHexColor = try container.decodeIfPresent(String.self, forKey: .backgroundHexColor) ?? "F2F2F7"
        manifest = try container.decodeIfPresent(FormManifest.self, forKey: .manifest) ?? FormManifest.compose(
            creatorName: "Unknown",
            questions: questions,
            privacyNote: "Review manifest before sharing."
        )
        ownerAccessKey = try container.decodeIfPresent(String.self, forKey: .ownerAccessKey) ?? UUID().uuidString
    }
}

struct FilledOutFormDocument: Codable, Hashable, Sendable {
    var formID: UUID
    var formName: String
    var answeredAt: Date
    var answers: [UUID: String]
    var responderName: String
    var ownerAccessKey: String

    init(
        formID: UUID,
        formName: String,
        answeredAt: Date,
        answers: [UUID: String],
        responderName: String,
        ownerAccessKey: String = ""
    ) {
        self.formID = formID
        self.formName = formName
        self.answeredAt = answeredAt
        self.answers = answers
        self.responderName = responderName
        self.ownerAccessKey = ownerAccessKey
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        formID = try container.decode(UUID.self, forKey: .formID)
        formName = try container.decodeIfPresent(String.self, forKey: .formName) ?? "Form"
        answeredAt = try container.decodeIfPresent(Date.self, forKey: .answeredAt) ?? Date()
        answers = try container.decodeIfPresent([UUID: String].self, forKey: .answers) ?? [:]
        responderName = try container.decodeIfPresent(String.self, forKey: .responderName) ?? "Anonymous"
        ownerAccessKey = try container.decodeIfPresent(String.self, forKey: .ownerAccessKey) ?? ""
    }
}
