import Foundation

@MainActor
final class WhiteboardViewTools: ObservableObject {
    static let shared = WhiteboardViewTools()

    // MARK: - Tool Entry

    struct ToolEntry: Identifiable, Hashable {
        let id: String
        let displayName: String
        let iconName: String
        let category: ToolCategory
        let interactionMode: InteractionMode
        let targetElementTypes: [CanvasElement.ElementKind]
        let configuration: ToolConfiguration
        let gestureBinding: GestureBinding

        static func == (lhs: ToolEntry, rhs: ToolEntry) -> Bool {
            lhs.id == rhs.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }

    enum ToolCategory: String, CaseIterable {
        case drawing
        case shapes
        case annotation
        case media
        case utility
        case embedding
        case background
        case selection
    }

    enum InteractionMode: String {
        case draw
        case select
        case insert
        case transform
    }

    struct ToolConfiguration: Hashable {
        var defaultColorHex: String
        var defaultStrokeWidth: Double
        var defaultFontSize: Double
        var supportsResize: Bool
        var supportsRotation: Bool

        init(
            defaultColorHex: String = "FFFFFF",
            defaultStrokeWidth: Double = 2,
            defaultFontSize: Double = 16,
            supportsResize: Bool = true,
            supportsRotation: Bool = false
        ) {
            self.defaultColorHex = defaultColorHex
            self.defaultStrokeWidth = defaultStrokeWidth
            self.defaultFontSize = defaultFontSize
            self.supportsResize = supportsResize
            self.supportsRotation = supportsRotation
        }
    }

    enum GestureBinding: String, Hashable {
        case drag
        case tap
        case longPress
        case continuousDraw
    }

    // MARK: - Tool Registry

    @Published private(set) var allTools: [ToolEntry] = []

    private init() {
        registerAllTools()
    }

    func tool(id: String) -> ToolEntry? {
        allTools.first { $0.id == id }
    }

    func tools(for category: ToolCategory) -> [ToolEntry] {
        allTools.filter { $0.category == category }
    }

    // MARK: - Registration

    private func registerAllTools() {
        allTools = [
            // Selection & Transform
            ToolEntry(
                id: "select",
                displayName: "Select",
                iconName: "cursorarrow",
                category: .selection,
                interactionMode: .select,
                targetElementTypes: CanvasElement.ElementKind.allCases,
                configuration: ToolConfiguration(supportsResize: true, supportsRotation: true),
                gestureBinding: .tap
            ),
            ToolEntry(
                id: "transform",
                displayName: "Transform",
                iconName: "arrow.up.left.and.arrow.down.right",
                category: .selection,
                interactionMode: .transform,
                targetElementTypes: CanvasElement.ElementKind.allCases,
                configuration: ToolConfiguration(supportsResize: true, supportsRotation: true),
                gestureBinding: .drag
            ),

            // Drawing Tools
            ToolEntry(
                id: "pen",
                displayName: "Pen",
                iconName: "pencil",
                category: .drawing,
                interactionMode: .draw,
                targetElementTypes: [.drawing],
                configuration: ToolConfiguration(defaultStrokeWidth: 2),
                gestureBinding: .continuousDraw
            ),
            ToolEntry(
                id: "brush",
                displayName: "Brush",
                iconName: "paintbrush",
                category: .drawing,
                interactionMode: .draw,
                targetElementTypes: [.drawing],
                configuration: ToolConfiguration(defaultStrokeWidth: 6),
                gestureBinding: .continuousDraw
            ),
            ToolEntry(
                id: "eraser",
                displayName: "Eraser",
                iconName: "eraser",
                category: .drawing,
                interactionMode: .draw,
                targetElementTypes: [.drawing],
                configuration: ToolConfiguration(defaultStrokeWidth: 12),
                gestureBinding: .continuousDraw
            ),
            ToolEntry(
                id: "highlighter",
                displayName: "Highlight",
                iconName: "highlighter",
                category: .drawing,
                interactionMode: .draw,
                targetElementTypes: [.drawing],
                configuration: ToolConfiguration(defaultColorHex: "FBBF24", defaultStrokeWidth: 10),
                gestureBinding: .continuousDraw
            ),

            // Shapes
            ToolEntry(
                id: "rectangle",
                displayName: "Rect",
                iconName: "rectangle",
                category: .shapes,
                interactionMode: .insert,
                targetElementTypes: [.rectangle],
                configuration: ToolConfiguration(defaultColorHex: "3B82F6"),
                gestureBinding: .tap
            ),
            ToolEntry(
                id: "circle",
                displayName: "Circle",
                iconName: "circle",
                category: .shapes,
                interactionMode: .insert,
                targetElementTypes: [.circle],
                configuration: ToolConfiguration(defaultColorHex: "8B5CF6"),
                gestureBinding: .tap
            ),
            ToolEntry(
                id: "arrow",
                displayName: "Arrow",
                iconName: "arrow.right",
                category: .shapes,
                interactionMode: .insert,
                targetElementTypes: [.arrow],
                configuration: ToolConfiguration(defaultColorHex: "FFFFFF"),
                gestureBinding: .tap
            ),
            ToolEntry(
                id: "connector-tool",
                displayName: "Connect",
                iconName: "link",
                category: .shapes,
                interactionMode: .select,
                targetElementTypes: [.connector],
                configuration: ToolConfiguration(defaultColorHex: "06B6D4"),
                gestureBinding: .tap
            ),

            // Annotation
            ToolEntry(
                id: "sticky-note",
                displayName: "Sticky",
                iconName: "note.text",
                category: .annotation,
                interactionMode: .insert,
                targetElementTypes: [.stickyNote],
                configuration: ToolConfiguration(defaultColorHex: "FBBF24", defaultFontSize: 14),
                gestureBinding: .tap
            ),
            ToolEntry(
                id: "text-tool",
                displayName: "Text",
                iconName: "textformat",
                category: .annotation,
                interactionMode: .insert,
                targetElementTypes: [.text],
                configuration: ToolConfiguration(defaultColorHex: "F9FAFB", defaultFontSize: 16),
                gestureBinding: .tap
            ),

            // Media
            ToolEntry(
                id: "media-placeholder",
                displayName: "Media",
                iconName: "photo.on.rectangle",
                category: .media,
                interactionMode: .insert,
                targetElementTypes: [.mediaPlaceholder, .image],
                configuration: ToolConfiguration(defaultColorHex: "6B7280"),
                gestureBinding: .tap
            ),

            // Utility
            ToolEntry(
                id: "timer",
                displayName: "Timer",
                iconName: "timer",
                category: .utility,
                interactionMode: .insert,
                targetElementTypes: [.text],
                configuration: ToolConfiguration(defaultColorHex: "F43F5E"),
                gestureBinding: .tap
            ),
            ToolEntry(
                id: "counter",
                displayName: "Counter",
                iconName: "number",
                category: .utility,
                interactionMode: .insert,
                targetElementTypes: [.text],
                configuration: ToolConfiguration(defaultColorHex: "14B8A6"),
                gestureBinding: .tap
            ),

            // Embedding
            ToolEntry(
                id: "embed-link",
                displayName: "Link",
                iconName: "link.badge.plus",
                category: .embedding,
                interactionMode: .insert,
                targetElementTypes: [.text],
                configuration: ToolConfiguration(defaultColorHex: "6366F1"),
                gestureBinding: .tap
            ),
            ToolEntry(
                id: "embed-video",
                displayName: "Video",
                iconName: "play.rectangle",
                category: .embedding,
                interactionMode: .insert,
                targetElementTypes: [.mediaPlaceholder],
                configuration: ToolConfiguration(defaultColorHex: "DC2626"),
                gestureBinding: .tap
            ),

            // Background
            ToolEntry(
                id: "bg-solid",
                displayName: "BG Color",
                iconName: "paintpalette",
                category: .background,
                interactionMode: .select,
                targetElementTypes: [],
                configuration: ToolConfiguration(defaultColorHex: "0F172A"),
                gestureBinding: .tap
            ),
            ToolEntry(
                id: "bg-gradient",
                displayName: "Gradient",
                iconName: "circle.lefthalf.filled",
                category: .background,
                interactionMode: .select,
                targetElementTypes: [],
                configuration: ToolConfiguration(),
                gestureBinding: .tap
            ),
        ]
    }
}
