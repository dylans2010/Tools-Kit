import Foundation
import Combine

@MainActor
public final class AISlidesTemplateManager: ObservableObject {
    nonisolated(unsafe) public static let shared = AISlidesTemplateManager()

    @Published public private(set) var templates: [SlideTemplate] = []
    @Published public private(set) var categories: [TemplateCategory] = TemplateCategory.allCases
    @Published public private(set) var favoriteIDs: Set<UUID> = []

    private init() {
        loadBuiltInTemplates()
    }

    // MARK: - Template CRUD

    public func createTemplate(name: String, description: String, category: TemplateCategory, slideLayouts: [TemplateSlideLayout]) -> SlideTemplate {
        let template = SlideTemplate(name: name, description: description, category: category, slideLayouts: slideLayouts)
        templates.append(template)
        SDKEventBus.shared.publish(SDKBusEvent(
            channel: "slides.templates",
            name: "template.created",
            data: ["name": name, "category": category.rawValue]
        ))
        return template
    }

    public func deleteTemplate(id: UUID) {
        templates.removeAll { $0.id == id }
        favoriteIDs.remove(id)
    }

    public func duplicateTemplate(id: UUID) -> SlideTemplate? {
        guard let original = templates.first(where: { $0.id == id }) else { return nil }
        return createTemplate(
            name: "\(original.name) (Copy)",
            description: original.description,
            category: original.category,
            slideLayouts: original.slideLayouts
        )
    }

    // MARK: - Favorites

    public func toggleFavorite(id: UUID) {
        if favoriteIDs.contains(id) {
            favoriteIDs.remove(id)
        } else {
            favoriteIDs.insert(id)
        }
    }

    public func isFavorite(id: UUID) -> Bool {
        favoriteIDs.contains(id)
    }

    // MARK: - Queries

    public func templates(for category: TemplateCategory) -> [SlideTemplate] {
        templates.filter { $0.category == category }
    }

    public func search(_ query: String) -> [SlideTemplate] {
        guard !query.isEmpty else { return templates }
        let lowered = query.lowercased()
        return templates.filter {
            $0.name.lowercased().contains(lowered) ||
            $0.description.lowercased().contains(lowered) ||
            $0.tags.contains(where: { $0.lowercased().contains(lowered) })
        }
    }

    public func favorites() -> [SlideTemplate] {
        templates.filter { favoriteIDs.contains($0.id) }
    }

    // MARK: - Apply Template

    public func applyTemplate(id: UUID, title: String, customContent: [String: String] = [:]) -> SlideDeck? {
        guard let template = templates.first(where: { $0.id == id }) else { return nil }

        var slides: [Slide] = []
        for layout in template.slideLayouts {
            let slideTitle = customContent["\(layout.name).title"] ?? layout.defaultTitle
            let bullets = layout.defaultBullets
            let slide = Slide(
                title: slideTitle,
                bullets: bullets,
                speakerNotes: layout.defaultNotes
            )
            slides.append(slide)
        }

        return SlideDeck(title: title, slides: slides)
    }

    // MARK: - Built-in Templates

    private func loadBuiltInTemplates() {
        templates = [
            SlideTemplate(
                name: "Business Pitch",
                description: "Professional pitch deck for investors and stakeholders",
                category: .business,
                slideLayouts: [
                    TemplateSlideLayout(name: "Title", defaultTitle: "Company Name", defaultBullets: ["Tagline goes here"]),
                    TemplateSlideLayout(name: "Problem", defaultTitle: "The Problem", defaultBullets: ["Pain point 1", "Pain point 2", "Market gap"]),
                    TemplateSlideLayout(name: "Solution", defaultTitle: "Our Solution", defaultBullets: ["Key feature 1", "Key feature 2", "Key differentiator"]),
                    TemplateSlideLayout(name: "Market", defaultTitle: "Market Opportunity", defaultBullets: ["TAM/SAM/SOM", "Growth rate", "Target segment"]),
                    TemplateSlideLayout(name: "Ask", defaultTitle: "The Ask", defaultBullets: ["Funding amount", "Use of funds", "Timeline"])
                ],
                tags: ["pitch", "investor", "startup"]
            ),
            SlideTemplate(
                name: "Technical Overview",
                description: "Architecture and system design presentation",
                category: .technical,
                slideLayouts: [
                    TemplateSlideLayout(name: "Title", defaultTitle: "System Overview", defaultBullets: ["Architecture deep dive"]),
                    TemplateSlideLayout(name: "Architecture", defaultTitle: "Architecture", defaultBullets: ["Component 1", "Component 2", "Data flow"]),
                    TemplateSlideLayout(name: "Stack", defaultTitle: "Tech Stack", defaultBullets: ["Frontend", "Backend", "Infrastructure"]),
                    TemplateSlideLayout(name: "Performance", defaultTitle: "Performance", defaultBullets: ["Latency metrics", "Throughput", "Scalability"]),
                    TemplateSlideLayout(name: "Roadmap", defaultTitle: "Technical Roadmap", defaultBullets: ["Phase 1", "Phase 2", "Phase 3"])
                ],
                tags: ["architecture", "engineering", "system"]
            ),
            SlideTemplate(
                name: "Project Status",
                description: "Weekly or monthly project status update",
                category: .project,
                slideLayouts: [
                    TemplateSlideLayout(name: "Title", defaultTitle: "Project Status Update", defaultBullets: ["Date: [Today]"]),
                    TemplateSlideLayout(name: "Summary", defaultTitle: "Executive Summary", defaultBullets: ["Overall status", "Key milestone", "Next deadline"]),
                    TemplateSlideLayout(name: "Progress", defaultTitle: "Progress", defaultBullets: ["Completed items", "In progress", "Blocked items"]),
                    TemplateSlideLayout(name: "Risks", defaultTitle: "Risks & Issues", defaultBullets: ["Risk 1", "Mitigation plan", "Impact assessment"]),
                    TemplateSlideLayout(name: "Next Steps", defaultTitle: "Next Steps", defaultBullets: ["Action item 1", "Action item 2", "Timeline"])
                ],
                tags: ["status", "update", "report"]
            ),
            SlideTemplate(
                name: "Educational Lesson",
                description: "Teaching and training presentation",
                category: .education,
                slideLayouts: [
                    TemplateSlideLayout(name: "Title", defaultTitle: "Lesson Title", defaultBullets: ["Learning objectives"]),
                    TemplateSlideLayout(name: "Overview", defaultTitle: "What You Will Learn", defaultBullets: ["Objective 1", "Objective 2", "Objective 3"]),
                    TemplateSlideLayout(name: "Content", defaultTitle: "Key Concepts", defaultBullets: ["Concept 1", "Concept 2", "Example"]),
                    TemplateSlideLayout(name: "Practice", defaultTitle: "Practice Exercise", defaultBullets: ["Exercise description", "Expected outcome"]),
                    TemplateSlideLayout(name: "Summary", defaultTitle: "Summary & Review", defaultBullets: ["Key takeaway 1", "Key takeaway 2", "Further reading"])
                ],
                tags: ["teaching", "training", "lesson"]
            ),
            SlideTemplate(
                name: "Creative Brief",
                description: "Design and creative project overview",
                category: .creative,
                slideLayouts: [
                    TemplateSlideLayout(name: "Title", defaultTitle: "Creative Brief", defaultBullets: ["Project name"]),
                    TemplateSlideLayout(name: "Objective", defaultTitle: "Objective", defaultBullets: ["Goal", "Target audience", "Key message"]),
                    TemplateSlideLayout(name: "Inspiration", defaultTitle: "Mood & Inspiration", defaultBullets: ["Visual direction", "Tone", "References"]),
                    TemplateSlideLayout(name: "Deliverables", defaultTitle: "Deliverables", defaultBullets: ["Asset 1", "Asset 2", "Formats & sizes"]),
                    TemplateSlideLayout(name: "Timeline", defaultTitle: "Timeline", defaultBullets: ["Draft review", "Final delivery", "Launch date"])
                ],
                tags: ["design", "creative", "brief"]
            )
        ]
    }
}

// MARK: - Models

public struct SlideTemplate: Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var description: String
    public var category: TemplateCategory
    public var slideLayouts: [TemplateSlideLayout]
    public var tags: [String]
    public let createdAt: Date

    public init(name: String, description: String, category: TemplateCategory, slideLayouts: [TemplateSlideLayout], tags: [String] = []) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.category = category
        self.slideLayouts = slideLayouts
        self.tags = tags
        self.createdAt = Date()
    }
}

public struct TemplateSlideLayout: Identifiable, Codable, Sendable {
    public let id: UUID
    public let name: String
    public let defaultTitle: String
    public let defaultBullets: [String]
    public let defaultNotes: String?

    public init(name: String, defaultTitle: String, defaultBullets: [String], defaultNotes: String? = nil) {
        self.id = UUID()
        self.name = name
        self.defaultTitle = defaultTitle
        self.defaultBullets = defaultBullets
        self.defaultNotes = defaultNotes
    }
}

public enum TemplateCategory: String, Codable, CaseIterable, Sendable, Identifiable {
    case business, technical, project, education, creative, marketing, general

    public var id: String { rawValue }

    public var displayName: String {
        rawValue.capitalized
    }

    public var icon: String {
        switch self {
        case .business: return "briefcase"
        case .technical: return "wrench.and.screwdriver"
        case .project: return "checklist"
        case .education: return "graduationcap"
        case .creative: return "paintbrush"
        case .marketing: return "megaphone"
        case .general: return "square.grid.2x2"
        }
    }
}
