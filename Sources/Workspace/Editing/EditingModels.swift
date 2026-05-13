import Foundation
import SwiftUI

/// Defines the type of a layer in the media editor.
enum LayerType: String, Codable {
    case image
    case video
    case text
    case shape
    case brush
}

/// Represents a blend mode for a layer.
enum BlendMode: String, Codable {
    case normal
    case multiply
    case screen
    case overlay
    case darken
    case lighten
}

/// Represents a filter applied to a layer.
struct MediaFilter: Codable, Identifiable {
    let id: UUID
    let name: String
    var intensity: Double // 0.0 to 1.0
}

/// Represents a single layer in an editing project.
struct EditingLayer: Codable, Identifiable {
    let id: UUID
    var name: String
    var type: LayerType
    var isVisible: Bool = true
    var opacity: Double = 1.0
    var blendMode: BlendMode = .normal

    // Transform
    var position: CGPoint
    var scale: CGFloat
    var rotation: CGFloat // In radians

    // Content-specific data
    var resourceID: String? // URL or internal identifier for image/video
    var textContent: String?
    var shapeData: Data?

    // Non-destructive adjustments per layer
    var adjustments: LayerAdjustments = LayerAdjustments()

    // Filters applied to this layer
    var filters: [MediaFilter] = []

    var metadata: [String: String] = [:]
}

/// Non-destructive adjustments stored as modifiers on a layer.
struct LayerAdjustments: Codable, Equatable {
    var brightness: Double = 0.0
    var contrast: Double = 1.0
    var saturation: Double = 1.0
    var temperature: Double = 0.0
}

/// Represents a track in the editing timeline.
struct TimelineTrack: Codable, Identifiable {
    let id: UUID
    var name: String
    var layerIDs: [UUID]
    var isMuted: Bool = false
    var isLocked: Bool = false
}

/// Represents a media editing project.
struct EditingProject: Codable, Identifiable {
    var id: UUID
    var name: String
    var ownerID: UUID
    var layers: [EditingLayer]
    var timelineTracks: [TimelineTrack]
    var canvasSize: CGSize

    var createdAt: Date
    var updatedAt: Date

    var previewImageID: String?
    var metadata: [String: String] = [:]
}
