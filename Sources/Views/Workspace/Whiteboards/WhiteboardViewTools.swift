import SwiftUI

@MainActor
final class WhiteboardViewTools: ObservableObject {
    static let shared = WhiteboardViewTools()

    // MARK: - Tool Entry

    struct ToolEntry: Identifiable, Hashable, Sendable {
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

    enum ToolCategory: String, CaseIterable, Sendable {
        case drawing
        case shapes
        case annotation
        case media
        case utility
        case embedding
        case background
        case selection
    }

    enum InteractionMode: String, Sendable {
        case draw
        case select
        case insert
        case transform
    }

    struct ToolConfiguration: Hashable, Sendable {
        var defaultColorHex: String
        var defaultStrokeWidth: Double
        var defaultFontSize: Double
        var supportsResize: Bool
        var supportsRotation: Bool
        var defaultOpacity: Double
        var drawingStyle: DrawingStyle
        var minStrokeWidth: Double
        var maxStrokeWidth: Double

        init(
            defaultColorHex: String = "FFFFFF",
            defaultStrokeWidth: Double = 2,
            defaultFontSize: Double = 16,
            supportsResize: Bool = true,
            supportsRotation: Bool = false,
            defaultOpacity: Double = 1.0,
            drawingStyle: DrawingStyle = .solid,
            minStrokeWidth: Double = 0.5,
            maxStrokeWidth: Double = 50
        ) {
            self.defaultColorHex = defaultColorHex
            self.defaultStrokeWidth = defaultStrokeWidth
            self.defaultFontSize = defaultFontSize
            self.supportsResize = supportsResize
            self.supportsRotation = supportsRotation
            self.defaultOpacity = defaultOpacity
            self.drawingStyle = drawingStyle
            self.minStrokeWidth = minStrokeWidth
            self.maxStrokeWidth = maxStrokeWidth
        }
    }

    enum DrawingStyle: String, Hashable, CaseIterable, Sendable {
        case solid
        case dashed
        case dotted
        case calligraphy
        case airbrush
        case charcoal
        case crayon
        case watercolor
        case neon
        case spray
        case marker
        case inkWash
        case stipple
        case chiselTip
        case flatBrush
        case fanBrush
        case sponge
        case palette
        case smudge
        case blur
    }

    enum GestureBinding: String, Hashable, Sendable {
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
                configuration: ToolConfiguration(defaultStrokeWidth: 2, drawingStyle: .solid),
                gestureBinding: .continuousDraw
            ),
            ToolEntry(
                id: "brush",
                displayName: "Brush",
                iconName: "paintbrush",
                category: .drawing,
                interactionMode: .draw,
                targetElementTypes: [.drawing],
                configuration: ToolConfiguration(defaultStrokeWidth: 6, drawingStyle: .solid),
                gestureBinding: .continuousDraw
            ),
            ToolEntry(
                id: "eraser",
                displayName: "Eraser",
                iconName: "eraser",
                category: .drawing,
                interactionMode: .draw,
                targetElementTypes: [.drawing],
                configuration: ToolConfiguration(defaultStrokeWidth: 12, drawingStyle: .solid),
                gestureBinding: .continuousDraw
            ),
            ToolEntry(
                id: "highlighter",
                displayName: "Highlight",
                iconName: "highlighter",
                category: .drawing,
                interactionMode: .draw,
                targetElementTypes: [.drawing],
                configuration: ToolConfiguration(defaultColorHex: "FBBF24", defaultStrokeWidth: 10, defaultOpacity: 0.4, drawingStyle: .marker),
                gestureBinding: .continuousDraw
            ),
            ToolEntry(
                id: "marker",
                displayName: "Marker",
                iconName: "pencil.tip",
                category: .drawing,
                interactionMode: .draw,
                targetElementTypes: [.drawing],
                configuration: ToolConfiguration(defaultColorHex: "EF4444", defaultStrokeWidth: 8, defaultOpacity: 0.85, drawingStyle: .marker),
                gestureBinding: .continuousDraw
            ),
            ToolEntry(
                id: "calligraphy",
                displayName: "Calligraphy",
                iconName: "pencil.and.outline",
                category: .drawing,
                interactionMode: .draw,
                targetElementTypes: [.drawing],
                configuration: ToolConfiguration(defaultStrokeWidth: 3, drawingStyle: .calligraphy, minStrokeWidth: 1, maxStrokeWidth: 20),
                gestureBinding: .continuousDraw
            ),
            ToolEntry(
                id: "fountain-pen",
                displayName: "Fountain",
                iconName: "pencil.line",
                category: .drawing,
                interactionMode: .draw,
                targetElementTypes: [.drawing],
                configuration: ToolConfiguration(defaultColorHex: "1E3A5F", defaultStrokeWidth: 2.5, drawingStyle: .calligraphy),
                gestureBinding: .continuousDraw
            ),
            ToolEntry(
                id: "fine-liner",
                displayName: "Fine Liner",
                iconName: "line.diagonal",
                category: .drawing,
                interactionMode: .draw,
                targetElementTypes: [.drawing],
                configuration: ToolConfiguration(defaultStrokeWidth: 1, drawingStyle: .solid, minStrokeWidth: 0.5, maxStrokeWidth: 3),
                gestureBinding: .continuousDraw
            ),
            ToolEntry(
                id: "charcoal",
                displayName: "Charcoal",
                iconName: "scribble.variable",
                category: .drawing,
                interactionMode: .draw,
                targetElementTypes: [.drawing],
                configuration: ToolConfiguration(defaultColorHex: "374151", defaultStrokeWidth: 8, defaultOpacity: 0.7, drawingStyle: .charcoal, maxStrokeWidth: 40),
                gestureBinding: .continuousDraw
            ),
            ToolEntry(
                id: "crayon",
                displayName: "Crayon",
                iconName: "pencil.tip.crop.circle",
                category: .drawing,
                interactionMode: .draw,
                targetElementTypes: [.drawing],
                configuration: ToolConfiguration(defaultColorHex: "F59E0B", defaultStrokeWidth: 10, defaultOpacity: 0.8, drawingStyle: .crayon, maxStrokeWidth: 30),
                gestureBinding: .continuousDraw
            ),
            ToolEntry(
                id: "watercolor",
                displayName: "Watercolor",
                iconName: "drop.fill",
                category: .drawing,
                interactionMode: .draw,
                targetElementTypes: [.drawing],
                configuration: ToolConfiguration(defaultColorHex: "3B82F6", defaultStrokeWidth: 14, defaultOpacity: 0.3, drawingStyle: .watercolor, maxStrokeWidth: 60),
                gestureBinding: .continuousDraw
            ),
            ToolEntry(
                id: "airbrush",
                displayName: "Airbrush",
                iconName: "aqi.medium",
                category: .drawing,
                interactionMode: .draw,
                targetElementTypes: [.drawing],
                configuration: ToolConfiguration(defaultColorHex: "8B5CF6", defaultStrokeWidth: 20, defaultOpacity: 0.25, drawingStyle: .airbrush, maxStrokeWidth: 80),
                gestureBinding: .continuousDraw
            ),
            ToolEntry(
                id: "spray-can",
                displayName: "Spray Can",
                iconName: "sprinkler.and.droplets.fill",
                category: .drawing,
                interactionMode: .draw,
                targetElementTypes: [.drawing],
                configuration: ToolConfiguration(defaultColorHex: "EC4899", defaultStrokeWidth: 24, defaultOpacity: 0.35, drawingStyle: .spray, maxStrokeWidth: 60),
                gestureBinding: .continuousDraw
            ),
            ToolEntry(
                id: "neon-pen",
                displayName: "Neon",
                iconName: "light.max",
                category: .drawing,
                interactionMode: .draw,
                targetElementTypes: [.drawing],
                configuration: ToolConfiguration(defaultColorHex: "00FF88", defaultStrokeWidth: 4, drawingStyle: .neon),
                gestureBinding: .continuousDraw
            ),
            ToolEntry(
                id: "dashed-pen",
                displayName: "Dashed",
                iconName: "line.3.horizontal",
                category: .drawing,
                interactionMode: .draw,
                targetElementTypes: [.drawing],
                configuration: ToolConfiguration(defaultStrokeWidth: 2, drawingStyle: .dashed),
                gestureBinding: .continuousDraw
            ),
            ToolEntry(
                id: "dotted-pen",
                displayName: "Dotted",
                iconName: "ellipsis",
                category: .drawing,
                interactionMode: .draw,
                targetElementTypes: [.drawing],
                configuration: ToolConfiguration(defaultStrokeWidth: 3, drawingStyle: .dotted),
                gestureBinding: .continuousDraw
            ),
            ToolEntry(
                id: "ink-wash",
                displayName: "Ink Wash",
                iconName: "drop.halffull",
                category: .drawing,
                interactionMode: .draw,
                targetElementTypes: [.drawing],
                configuration: ToolConfiguration(defaultColorHex: "1F2937", defaultStrokeWidth: 10, defaultOpacity: 0.5, drawingStyle: .inkWash, maxStrokeWidth: 40),
                gestureBinding: .continuousDraw
            ),
            ToolEntry(
                id: "stipple",
                displayName: "Stipple",
                iconName: "circle.grid.3x3.fill",
                category: .drawing,
                interactionMode: .draw,
                targetElementTypes: [.drawing],
                configuration: ToolConfiguration(defaultStrokeWidth: 3, defaultOpacity: 0.6, drawingStyle: .stipple),
                gestureBinding: .continuousDraw
            ),
            ToolEntry(
                id: "chisel-tip",
                displayName: "Chisel Tip",
                iconName: "rectangle.portrait.fill",
                category: .drawing,
                interactionMode: .draw,
                targetElementTypes: [.drawing],
                configuration: ToolConfiguration(defaultColorHex: "D97706", defaultStrokeWidth: 6, drawingStyle: .chiselTip, maxStrokeWidth: 20),
                gestureBinding: .continuousDraw
            ),
            ToolEntry(
                id: "flat-brush",
                displayName: "Flat Brush",
                iconName: "paintbrush.pointed.fill",
                category: .drawing,
                interactionMode: .draw,
                targetElementTypes: [.drawing],
                configuration: ToolConfiguration(defaultColorHex: "059669", defaultStrokeWidth: 12, drawingStyle: .flatBrush, maxStrokeWidth: 40),
                gestureBinding: .continuousDraw
            ),
            ToolEntry(
                id: "fan-brush",
                displayName: "Fan Brush",
                iconName: "wind",
                category: .drawing,
                interactionMode: .draw,
                targetElementTypes: [.drawing],
                configuration: ToolConfiguration(defaultColorHex: "0EA5E9", defaultStrokeWidth: 16, defaultOpacity: 0.6, drawingStyle: .fanBrush, maxStrokeWidth: 50),
                gestureBinding: .continuousDraw
            ),
            ToolEntry(
                id: "sponge",
                displayName: "Sponge",
                iconName: "circle.dashed",
                category: .drawing,
                interactionMode: .draw,
                targetElementTypes: [.drawing],
                configuration: ToolConfiguration(defaultColorHex: "FCA5A5", defaultStrokeWidth: 20, defaultOpacity: 0.4, drawingStyle: .sponge, maxStrokeWidth: 60),
                gestureBinding: .continuousDraw
            ),
            ToolEntry(
                id: "palette-knife",
                displayName: "Palette Knife",
                iconName: "arrow.triangle.swap",
                category: .drawing,
                interactionMode: .draw,
                targetElementTypes: [.drawing],
                configuration: ToolConfiguration(defaultColorHex: "A78BFA", defaultStrokeWidth: 14, defaultOpacity: 0.7, drawingStyle: .palette, maxStrokeWidth: 30),
                gestureBinding: .continuousDraw
            ),
            ToolEntry(
                id: "smudge",
                displayName: "Smudge",
                iconName: "hand.draw.fill",
                category: .drawing,
                interactionMode: .draw,
                targetElementTypes: [.drawing],
                configuration: ToolConfiguration(defaultStrokeWidth: 16, defaultOpacity: 0.5, drawingStyle: .smudge, maxStrokeWidth: 40),
                gestureBinding: .continuousDraw
            ),
            ToolEntry(
                id: "blur-tool",
                displayName: "Blur",
                iconName: "aqi.low",
                category: .drawing,
                interactionMode: .draw,
                targetElementTypes: [.drawing],
                configuration: ToolConfiguration(defaultStrokeWidth: 20, defaultOpacity: 0.3, drawingStyle: .blur, maxStrokeWidth: 50),
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


struct WhiteboardDrawingToolsSection: View {
    let tools: [WhiteboardViewTools.ToolEntry]
    let onSelect: (WhiteboardViewTools.ToolEntry) -> Void

    var body: some View {
        Section("Drawing Tools") {
            ForEach(tools) { tool in
                Button {
                    onSelect(tool)
                } label: {
                    Label(tool.displayName, systemImage: tool.iconName)
                }
            }
        }
    }
}
