import Foundation

@MainActor
struct WhiteboardAIEngine: Sendable {
    private let processor = WhiteboardGraphProcessor()

    func expandNodes(_ nodes: [WhiteboardNode]) -> [WhiteboardNode] {
        nodes.map { node in
            var expanded = node
            if expanded.content.split(separator: " ").count < 6 {
                expanded.content = expanded.content + " — include context, impact, and next step"
            }
            return expanded
        }
    }

    func summarizeClusters(board: WhiteboardBoard) -> [WhiteboardSlideSection] {
        processor.buildSections(from: board)
    }

    func slideInput(
        from board: WhiteboardBoard,
        rawText: String,
        tone: SlideTone,
        audience: SlideAudience,
        slideCount: Int,
        includeImages: Bool,
        density: SlideVisualDensity,
        uploadedImages: [SlidePhotoAsset] = [],
        preferredThemeID: String? = nil,
        preferredStyleID: String? = nil
    ) -> SlideInput {
        let expandedNodes = expandNodes(board.nodes)
        let sectionBoard = WhiteboardBoard(id: board.id, title: board.title, nodes: expandedNodes, edges: board.edges, updatedAt: board.updatedAt)
        let sections = summarizeClusters(board: sectionBoard)

        return SlideInput(
            rawText: rawText,
            notes: sections.map(\.summary),
            whiteboardNodes: expandedNodes,
            documents: [],
            uploadedImages: uploadedImages,
            tone: tone,
            audience: audience,
            slideCount: slideCount,
            includeImages: includeImages,
            visualDensity: density,
            sections: sections,
            preferredThemeID: preferredThemeID,
            preferredStyleID: preferredStyleID
        )
    }
}
