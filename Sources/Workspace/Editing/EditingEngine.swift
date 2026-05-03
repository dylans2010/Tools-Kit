#if os(iOS)
import UIKit
import CoreGraphics
import QuartzCore

/// High-performance renderer for the media editing suite.
/// Uses UIKit, Core Animation, and Core Graphics for real-time composition.
final class EditingEngine: UIView {
    private var project: EditingProject?
    private var layerViews: [UUID: UIView] = [:]

    init(project: EditingProject) {
        self.project = project
        super.init(frame: .zero)
        setupCanvas()
        renderProject()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupCanvas() {
        guard let project = project else { return }
        backgroundColor = .black
        clipsToBounds = true
        // Set fixed canvas size based on project
        frame = CGRect(origin: .zero, size: project.canvasSize)
    }

    func updateProject(_ project: EditingProject) {
        self.project = project
        renderProject()
    }

    private func renderProject() {
        guard let project = project else { return }

        // Simple reconciliation logic
        // 1. Remove views for deleted layers
        let currentLayerIDs = Set(project.layers.map { $0.id })
        for (id, view) in layerViews where !currentLayerIDs.contains(id) {
            view.removeFromSuperview()
            layerViews.removeValue(forKey: id)
        }

        // 2. Add or update views for layers
        for (index, layer) in project.layers.enumerated() {
            let view = getOrCreateView(for: layer)
            updateView(view, with: layer)
            insertSubview(view, at: index)
        }
    }

    private func getOrCreateView(for layer: EditingLayer) -> UIView {
        if let existing = layerViews[layer.id] {
            return existing
        }

        let view: UIView
        switch layer.type {
        case .image:
            view = UIImageView()
            (view as? UIImageView)?.contentMode = .scaleAspectFill
        case .text:
            view = UILabel()
            (view as? UILabel)?.numberOfLines = 0
        default:
            view = UIView()
        }

        layerViews[layer.id] = view
        return view
    }

    private func updateView(_ view: UIView, with layer: EditingLayer) {
        view.isHidden = !layer.isVisible
        view.alpha = CGFloat(layer.opacity)

        // Transform
        view.center = layer.position
        view.transform = CGAffineTransform.identity
            .scaledBy(x: layer.scale, y: layer.scale)
            .rotated(by: layer.rotation)

        // Content
        if let label = view as? UILabel, let text = layer.textContent {
            label.text = text
            label.sizeToFit()
        }

        // Apply blend modes and filters via CALayer if needed
        // view.layer.compositingFilter = ... (Advanced Core Image integration)
    }

    // MARK: - Export

    func renderToImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, true, 0.0)
        defer { UIGraphicsEndImageContext() }

        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        layer.render(in: context)

        return UIGraphicsGetImageFromCurrentImageContext()
    }

    // MARK: - Image Operations

    func applyFilter(name: String, intensity: Double, to layerID: UUID) {
        guard var project = project,
              let index = project.layers.firstIndex(where: { $0.id == layerID }) else { return }

        let filter = MediaFilter(id: UUID(), name: name, intensity: intensity)
        project.layers[index].filters.append(filter)
        EditingManager.shared.saveProject(project)
    }

    func resizeCanvas(to size: CGSize) {
        guard var project = project else { return }
        project.canvasSize = size
        EditingManager.shared.saveProject(project)
        setupCanvas()
    }

    func cropLayer(id: UUID, rect: CGRect) {
        guard var project = project,
              let index = project.layers.firstIndex(where: { $0.id == id }),
              let view = layerViews[id] as? UIImageView,
              let image = view.image else { return }

        // Core Image Cropping
        guard let ciImage = CIImage(image: image) else { return }

        // Convert UIKit rect to CIImage coordinates (origin bottom-left)
        let ciRect = CGRect(x: rect.origin.x,
                           y: image.size.height - rect.origin.y - rect.size.height,
                           width: rect.size.width,
                           height: rect.size.height)

        let croppedCI = ciImage.cropped(to: ciRect)
        let context = CIContext(options: nil)
        if let cgImage = context.createCGImage(croppedCI, from: croppedCI.extent) {
            let croppedUI = UIImage(cgImage: cgImage)
            view.image = croppedUI

            // Update metadata to track the crop
            project.layers[index].metadata["crop_rect"] = NSCoder.string(for: rect)
            EditingManager.shared.saveProject(project)
        }
    }
}
#else
import SwiftUI

/// Fallback for non-iOS platforms.
struct EditingEngine: View {
    var body: some View {
        Text("Media Editing Engine (iOS Only)")
    }
}
#endif
