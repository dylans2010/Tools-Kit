import SwiftUI

// MARK: - Editor State

final class EditorState: ObservableObject {
    @Published var project: EditingProject
    @Published var selectedLayerID: UUID?
    @Published var selectedTool: EditorTool = .select
    @Published var canvasZoom: CGFloat = 1.0
    @Published var canvasOffset: CGSize = .zero
    @Published var isPlaying = false
    @Published var playheadPosition: Double = 0.0
    @Published var timelineDuration: Double = 30.0
    @Published var activePanel: EditorPanel = .tools

    @Published var brightness: Double = 0.0
    @Published var contrast: Double = 1.0
    @Published var saturation: Double = 1.0
    @Published var temperature: Double = 0.0
    @Published var selectedFilterName: String?

    @Published var showingAssetLibrary = false
    @Published var showingExportSheet = false
    @Published var showingKeyframeEditor = false
    @Published var showingTextOverlay = false
    @Published var overlayText = ""
    @Published var exportProgress: Double?
    @Published var exportError: String?

    let manager = EditingManager.shared

    var selectedLayer: EditingLayer? {
        project.layers.first { $0.id == selectedLayerID }
    }

    init(project: EditingProject) {
        self.project = project
    }

    func addLayer(type: LayerType, name: String) {
        let layer = EditingLayer(
            id: UUID(),
            name: name,
            type: type,
            position: CGPoint(x: project.canvasSize.width / 2, y: project.canvasSize.height / 2),
            scale: 1.0,
            rotation: 0
        )
        project.layers.append(layer)
        selectedLayerID = layer.id
        save()
    }

    func removeLayer(id: UUID) {
        project.layers.removeAll { $0.id == id }
        if selectedLayerID == id { selectedLayerID = nil }
        project.timelineTracks = project.timelineTracks.map { track in
            var t = track
            t.layerIDs.removeAll { $0 == id }
            return t
        }
        save()
    }

    func moveLayer(from: IndexSet, to: Int) {
        project.layers.move(fromOffsets: from, toOffset: to)
        save()
    }

    func applyFilter(name: String, intensity: Double) {
        guard let idx = project.layers.firstIndex(where: { $0.id == selectedLayerID }) else { return }
        let filter = MediaFilter(id: UUID(), name: name, intensity: intensity)
        project.layers[idx].filters.append(filter)
        save()
    }

    func removeFilter(filterID: UUID) {
        guard let layerIdx = project.layers.firstIndex(where: { $0.id == selectedLayerID }) else { return }
        project.layers[layerIdx].filters.removeAll { $0.id == filterID }
        save()
    }

    func addTimelineTrack(name: String) {
        let track = TimelineTrack(id: UUID(), name: name, layerIDs: [])
        project.timelineTracks.append(track)
        save()
    }

    func removeTimelineTrack(at offsets: IndexSet) {
        project.timelineTracks.remove(atOffsets: offsets)
        save()
    }

    func assignLayerToTrack(layerID: UUID, trackID: UUID) {
        guard let idx = project.timelineTracks.firstIndex(where: { $0.id == trackID }) else { return }
        if !project.timelineTracks[idx].layerIDs.contains(layerID) {
            project.timelineTracks[idx].layerIDs.append(layerID)
            save()
        }
    }

    func undo() {
        manager.undo(projectID: project.id)
        reload()
    }

    func redo() {
        manager.redo(projectID: project.id)
        reload()
    }

    func save() {
        project.updatedAt = Date()
        manager.saveProject(project)
    }

    func reload() {
        if let updated = manager.projects.first(where: { $0.id == project.id }) {
            project = updated
        }
    }

    func exportProject() {
        exportProgress = 0.0
        exportError = nil
        Task {
            do {
                await MainActor.run { exportProgress = 0.3 }
                let url = try await EditingFramework.shared.exportProject(projectID: project.id)
                await MainActor.run {
                    exportProgress = 1.0
                    print("Exported: \(url)")
                }
            } catch {
                await MainActor.run {
                    exportError = error.localizedDescription
                    exportProgress = nil
                }
            }
        }
    }
}

// MARK: - Enums

enum EditorTool: String, CaseIterable, Identifiable {
    case select = "Select"
    case crop = "Crop"
    case brush = "Brush"
    case text = "Text"
    case shape = "Shape"
    case filter = "Filter"
    case adjust = "Adjust"
    case transform = "Transform"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .select: return "cursorarrow"
        case .crop: return "crop"
        case .brush: return "paintbrush"
        case .text: return "textformat"
        case .shape: return "square.on.circle"
        case .filter: return "camera.filters"
        case .adjust: return "slider.horizontal.3"
        case .transform: return "arrow.up.left.and.arrow.down.right"
        }
    }
}

enum EditorPanel: String, CaseIterable, Identifiable {
    case tools = "Tools"
    case layers = "Layers"
    case timeline = "Timeline"
    case properties = "Properties"
    case assets = "Assets"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .tools: return "wrench"
        case .layers: return "square.3.layers.3d"
        case .timeline: return "timeline.selection"
        case .properties: return "slider.horizontal.3"
        case .assets: return "photo.on.rectangle"
        }
    }
}

// MARK: - FullEditorView

struct FullEditorView: View {
    let projectID: UUID
    @StateObject private var manager = EditingManager.shared
    @StateObject private var state: EditorState
    @Environment(\.dismiss) var dismiss

    init(projectID: UUID) {
        self.projectID = projectID
        let project = EditingManager.shared.projects.first { $0.id == projectID }
            ?? EditingProject(
                id: projectID,
                name: "Untitled",
                ownerID: UUID(),
                layers: [],
                timelineTracks: [],
                canvasSize: CGSize(width: 1920, height: 1080),
                createdAt: Date(),
                updatedAt: Date()
            )
        _state = StateObject(wrappedValue: EditorState(project: project))
    }

    var body: some View {
        VStack(spacing: 0) {
            editorToolbar
            Divider()

            GeometryReader { geo in
                if geo.size.width > 700 {
                    HStack(spacing: 0) {
                        toolRail
                        Divider()
                        canvasArea
                        Divider()
                        inspectorPanel
                            .frame(width: 280)
                    }
                } else {
                    VStack(spacing: 0) {
                        canvasArea
                        Divider()
                        compactPanels
                    }
                }
            }

            if hasVideoContent {
                Divider()
                timelinePanel
            }
        }
        .sheet(isPresented: $state.showingAssetLibrary) {
            NavigationStack { AssetLibraryView(state: state) }
                .presentationDetents([.large])
        }
        .sheet(isPresented: $state.showingExportSheet) {
            NavigationStack { ExportView(state: state) }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $state.showingTextOverlay) {
            NavigationStack { TextOverlaySheet(state: state) }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private var hasVideoContent: Bool {
        state.project.layers.contains { $0.type == .video } || !state.project.timelineTracks.isEmpty
    }

    // MARK: - Toolbar

    private var editorToolbar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
            }

            Text(state.project.name)
                .font(.headline)

            Spacer()

            HStack(spacing: 16) {
                Button { state.undo() } label: {
                    Image(systemName: "arrow.uturn.backward")
                }
                Button { state.redo() } label: {
                    Image(systemName: "arrow.uturn.forward")
                }
                Button { state.showingAssetLibrary = true } label: {
                    Image(systemName: "photo.on.rectangle.angled")
                }
                Button { state.showingExportSheet = true } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                        .font(.subheadline.bold())
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    // MARK: - Tool Rail

    private var toolRail: some View {
        VStack(spacing: 4) {
            ForEach(EditorTool.allCases) { tool in
                Button {
                    state.selectedTool = tool
                    if tool == .text { state.showingTextOverlay = true }
                } label: {
                    Image(systemName: tool.icon)
                        .frame(width: 36, height: 36)
                        .background(state.selectedTool == tool ? Color.accentColor.opacity(0.15) : Color.clear, in: RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.vertical, 8)
        .frame(width: 52)
        .background(.ultraThinMaterial)
    }

    // MARK: - Canvas

    private var canvasArea: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            canvasContent
                .scaleEffect(state.canvasZoom)
                .offset(state.canvasOffset)
                .gesture(canvasGestures)
        }
    }

    private var canvasContent: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(.background)
                .frame(
                    width: state.project.canvasSize.width * 0.2,
                    height: state.project.canvasSize.height * 0.2
                )
                .shadow(radius: 4)

            ForEach(state.project.layers.filter(\.isVisible)) { layer in
                CanvasLayerView(
                    layer: layer,
                    isSelected: layer.id == state.selectedLayerID,
                    onSelect: { state.selectedLayerID = layer.id }
                )
            }
        }
    }

    private var canvasGestures: some Gesture {
        SimultaneousGesture(
            MagnificationGesture()
                .onChanged { value in
                    state.canvasZoom = max(0.25, min(4.0, value))
                },
            DragGesture()
                .onChanged { value in
                    state.canvasOffset = value.translation
                }
        )
    }

    // MARK: - Inspector Panel

    private var inspectorPanel: some View {
        List {
            Section("Layers") {
                ForEach(state.project.layers) { layer in
                    HStack {
                        Image(systemName: iconFor(layer.type))
                            .foregroundStyle(layer.id == state.selectedLayerID ? Color.accentColor : Color.secondary)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(layer.name).font(.caption.bold())
                            Text(layer.type.rawValue.capitalized).font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: layer.isVisible ? "eye.fill" : "eye.slash.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { state.selectedLayerID = layer.id }
                    .listRowBackground(layer.id == state.selectedLayerID ? Color.accentColor.opacity(0.08) : nil)
                }
                .onMove(perform: state.moveLayer)
                .onDelete { offsets in
                    for idx in offsets {
                        state.removeLayer(id: state.project.layers[idx].id)
                    }
                }

                Menu {
                    Button("Image Layer") { state.addLayer(type: .image, name: "Image \(state.project.layers.count + 1)") }
                    Button("Video Layer") { state.addLayer(type: .video, name: "Video \(state.project.layers.count + 1)") }
                    Button("Text Layer") { state.addLayer(type: .text, name: "Text \(state.project.layers.count + 1)") }
                    Button("Shape Layer") { state.addLayer(type: .shape, name: "Shape \(state.project.layers.count + 1)") }
                } label: {
                    Label("Add Layer", systemImage: "plus")
                }
            }

            if let layer = state.selectedLayer {
                layerPropertiesSection(layer)
            }

            toolSpecificSection
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Layer Properties

    @ViewBuilder
    private func layerPropertiesSection(_ layer: EditingLayer) -> some View {
        Section("Properties") {
            LabeledContent("Name", value: layer.name)
            LabeledContent("Type", value: layer.type.rawValue.capitalized)
            LabeledContent("Position", value: "\(Int(layer.position.x)), \(Int(layer.position.y))")
            LabeledContent("Scale", value: String(format: "%.2f", layer.scale))
            LabeledContent("Rotation", value: "\(Int(layer.rotation * 180 / .pi))°")
            LabeledContent("Opacity", value: String(format: "%.0f%%", layer.opacity * 100))
            LabeledContent("Blend", value: layer.blendMode.rawValue.capitalized)
        }

        if !layer.filters.isEmpty {
            Section("Filters") {
                ForEach(layer.filters) { filter in
                    HStack {
                        Text(filter.name).font(.caption)
                        Spacer()
                        Text("\(Int(filter.intensity * 100))%").font(.caption2).foregroundStyle(.secondary)
                    }
                }
                .onDelete { offsets in
                    for idx in offsets {
                        state.removeFilter(filterID: layer.filters[idx].id)
                    }
                }
            }
        }
    }

    // MARK: - Tool-Specific Section

    @ViewBuilder
    private var toolSpecificSection: some View {
        switch state.selectedTool {
        case .filter:
            Section("Apply Filter") {
                ForEach(EditorFilterLibrary.filters, id: \.name) { preset in
                    Button {
                        state.applyFilter(name: preset.name, intensity: preset.defaultIntensity)
                    } label: {
                        HStack {
                            Image(systemName: preset.icon)
                            Text(preset.name).font(.caption)
                        }
                    }
                }
            }
        case .adjust:
            Section("Adjustments") {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Brightness").font(.caption2)
                    Slider(value: $state.brightness, in: -1...1)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Contrast").font(.caption2)
                    Slider(value: $state.contrast, in: 0...2)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Saturation").font(.caption2)
                    Slider(value: $state.saturation, in: 0...2)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Temperature").font(.caption2)
                    Slider(value: $state.temperature, in: -1...1)
                }
                Button("Apply Adjustments") {
                    state.applyFilter(name: "Adjustments", intensity: 1.0)
                }
            }
        case .transform:
            Section("Transform") {
                if let layerIdx = state.project.layers.firstIndex(where: { $0.id == state.selectedLayerID }) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Scale").font(.caption2)
                        Slider(
                            value: Binding(
                                get: { state.project.layers[layerIdx].scale },
                                set: {
                                    state.project.layers[layerIdx].scale = $0
                                    state.save()
                                }
                            ),
                            in: 0.1...5.0
                        )
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Rotation").font(.caption2)
                        Slider(
                            value: Binding(
                                get: { state.project.layers[layerIdx].rotation },
                                set: {
                                    state.project.layers[layerIdx].rotation = $0
                                    state.save()
                                }
                            ),
                            in: -.pi ... .pi
                        )
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Opacity").font(.caption2)
                        Slider(
                            value: Binding(
                                get: { state.project.layers[layerIdx].opacity },
                                set: {
                                    state.project.layers[layerIdx].opacity = $0
                                    state.save()
                                }
                            ),
                            in: 0...1
                        )
                    }
                }
            }
        case .crop:
            Section("Crop & Resize") {
                HStack {
                    Text("Canvas Size").font(.caption)
                    Spacer()
                    Text("\(Int(state.project.canvasSize.width))×\(Int(state.project.canvasSize.height))")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
                ForEach(CanvasPreset.allCases, id: \.name) { preset in
                    Button(preset.name) {
                        state.project.canvasSize = preset.size
                        state.save()
                    }
                    .font(.caption)
                }
            }
        default:
            EmptyView()
        }
    }

    // MARK: - Compact Panels (Mobile)

    private var compactPanels: some View {
        VStack(spacing: 0) {
            Picker("Panel", selection: $state.activePanel) {
                ForEach(EditorPanel.allCases) { panel in
                    Image(systemName: panel.icon).tag(panel)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)

            Group {
                switch state.activePanel {
                case .tools:
                    compactToolGrid
                case .layers:
                    compactLayerList
                case .timeline:
                    compactTimeline
                case .properties:
                    compactProperties
                case .assets:
                    compactAssets
                }
            }
            .frame(height: 160)
        }
        .background(.ultraThinMaterial)
    }

    private var compactToolGrid: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(EditorTool.allCases) { tool in
                    Button {
                        state.selectedTool = tool
                        if tool == .text { state.showingTextOverlay = true }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tool.icon)
                                .font(.title3)
                            Text(tool.rawValue)
                                .font(.system(size: 9))
                        }
                        .frame(width: 50, height: 50)
                        .background(state.selectedTool == tool ? Color.accentColor.opacity(0.15) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }

    private var compactLayerList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(state.project.layers) { layer in
                    VStack(spacing: 4) {
                        Image(systemName: iconFor(layer.type))
                            .font(.title3)
                        Text(layer.name)
                            .font(.system(size: 9))
                            .lineLimit(1)
                    }
                    .frame(width: 56, height: 56)
                    .background(
                        layer.id == state.selectedLayerID ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.1),
                        in: RoundedRectangle(cornerRadius: 8)
                    )
                    .onTapGesture { state.selectedLayerID = layer.id }
                }

                Button {
                    state.addLayer(type: .image, name: "Layer \(state.project.layers.count + 1)")
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 56, height: 56)
                        .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
    }

    private var compactTimeline: some View {
        VStack(spacing: 4) {
            playbackControls
            timelineTrackList
        }
        .padding(.horizontal, 8)
    }

    private var compactProperties: some View {
        List {
            if let layer = state.selectedLayer {
                LabeledContent("Name", value: layer.name)
                LabeledContent("Opacity", value: String(format: "%.0f%%", layer.opacity * 100))
                LabeledContent("Filters", value: "\(layer.filters.count)")
            } else {
                Text("Select a layer").font(.caption).foregroundStyle(.secondary)
            }
        }
        .listStyle(.plain)
    }

    private var compactAssets: some View {
        VStack {
            Button {
                state.showingAssetLibrary = true
            } label: {
                Label("Open Asset Library", systemImage: "photo.on.rectangle.angled")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
    }

    // MARK: - Timeline

    private var timelinePanel: some View {
        VStack(spacing: 0) {
            playbackControls
            Divider()
            timelineTrackList
        }
        .frame(height: 180)
        .background(.ultraThinMaterial)
    }

    private var playbackControls: some View {
        HStack(spacing: 16) {
            Button { state.playheadPosition = max(0, state.playheadPosition - 1) } label: {
                Image(systemName: "backward.fill")
            }
            Button { state.isPlaying.toggle() } label: {
                Image(systemName: state.isPlaying ? "pause.fill" : "play.fill")
            }
            Button { state.playheadPosition = min(state.timelineDuration, state.playheadPosition + 1) } label: {
                Image(systemName: "forward.fill")
            }

            Spacer()

            Text("\(formattedTime(state.playheadPosition)) / \(formattedTime(state.timelineDuration))")
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)

            Spacer()

            Button { state.addTimelineTrack(name: "Track \(state.project.timelineTracks.count + 1)") } label: {
                Image(systemName: "plus")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private var timelineTrackList: some View {
        ScrollView {
            VStack(spacing: 2) {
                ForEach(state.project.timelineTracks) { track in
                    TimelineTrackRow(
                        track: track,
                        layers: state.project.layers,
                        playheadPosition: state.playheadPosition,
                        duration: state.timelineDuration
                    )
                }
            }
        }
    }

    // MARK: - Helpers

    private func iconFor(_ type: LayerType) -> String {
        switch type {
        case .image: return "photo"
        case .video: return "video"
        case .text: return "textformat"
        case .shape: return "square"
        case .brush: return "paintbrush"
        }
    }

    private func formattedTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Canvas Layer

private struct CanvasLayerView: View {
    let layer: EditingLayer
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Group {
            switch layer.type {
            case .text:
                Text(layer.textContent ?? "Text")
                    .font(.title3)
            case .shape:
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 80, height: 60)
            case .image:
                Image(systemName: "photo")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
            case .video:
                Image(systemName: "video")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
            case .brush:
                Image(systemName: "scribble")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
            }
        }
        .opacity(layer.opacity)
        .scaleEffect(layer.scale)
        .rotationEffect(.radians(layer.rotation))
        .position(
            x: layer.position.x * 0.2,
            y: layer.position.y * 0.2
        )
        .overlay {
            if isSelected {
                Rectangle()
                    .stroke(Color.accentColor, lineWidth: 2)
                    .frame(width: 80, height: 60)
                    .position(
                        x: layer.position.x * 0.2,
                        y: layer.position.y * 0.2
                    )
            }
        }
        .onTapGesture(perform: onSelect)
    }
}

// MARK: - Timeline Track Row

private struct TimelineTrackRow: View {
    let track: TimelineTrack
    let layers: [EditingLayer]
    let playheadPosition: Double
    let duration: Double

    var trackLayers: [EditingLayer] {
        layers.filter { track.layerIDs.contains($0.id) }
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading) {
                Text(track.name)
                    .font(.caption2.bold())
                HStack(spacing: 4) {
                    Image(systemName: track.isMuted ? "speaker.slash" : "speaker.wave.2")
                        .font(.system(size: 8))
                    Image(systemName: track.isLocked ? "lock" : "lock.open")
                        .font(.system(size: 8))
                }
                .foregroundStyle(.secondary)
            }
            .frame(width: 80)
            .padding(.horizontal, 4)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.1))

                    ForEach(trackLayers) { layer in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(clipColor(for: layer.type).opacity(0.3))
                            .frame(width: max(30, geo.size.width / max(1, CGFloat(trackLayers.count))), height: 24)
                            .overlay {
                                Text(layer.name)
                                    .font(.system(size: 8))
                                    .lineLimit(1)
                            }
                    }

                    Rectangle()
                        .fill(Color.red)
                        .frame(width: 2)
                        .offset(x: geo.size.width * (playheadPosition / max(1, duration)))
                }
            }
            .frame(height: 32)
        }
        .padding(.vertical, 2)
    }

    private func clipColor(for type: LayerType) -> Color {
        switch type {
        case .video: return .blue
        case .image: return .green
        case .text: return .orange
        case .shape: return .purple
        case .brush: return .pink
        }
    }
}

// MARK: - Filter Library

enum EditorFilterLibrary {
    struct FilterPreset {
        let name: String
        let icon: String
        let defaultIntensity: Double
    }

    static let filters: [FilterPreset] = [
        FilterPreset(name: "Vivid", icon: "paintpalette", defaultIntensity: 0.7),
        FilterPreset(name: "Mono", icon: "circle.lefthalf.filled", defaultIntensity: 1.0),
        FilterPreset(name: "Warm", icon: "sun.max", defaultIntensity: 0.5),
        FilterPreset(name: "Cool", icon: "snowflake", defaultIntensity: 0.5),
        FilterPreset(name: "Dramatic", icon: "theatermasks", defaultIntensity: 0.8),
        FilterPreset(name: "Noir", icon: "moon.fill", defaultIntensity: 0.9),
        FilterPreset(name: "Fade", icon: "aqi.medium", defaultIntensity: 0.6),
        FilterPreset(name: "Sharpen", icon: "triangle", defaultIntensity: 0.4),
    ]
}

// MARK: - Canvas Presets

enum CanvasPreset: CaseIterable {
    case hd1080
    case hd720
    case square
    case portrait
    case landscape4K

    var name: String {
        switch self {
        case .hd1080: return "1080p (1920×1080)"
        case .hd720: return "720p (1280×720)"
        case .square: return "Square (1080×1080)"
        case .portrait: return "Portrait (1080×1920)"
        case .landscape4K: return "4K (3840×2160)"
        }
    }

    var size: CGSize {
        switch self {
        case .hd1080: return CGSize(width: 1920, height: 1080)
        case .hd720: return CGSize(width: 1280, height: 720)
        case .square: return CGSize(width: 1080, height: 1080)
        case .portrait: return CGSize(width: 1080, height: 1920)
        case .landscape4K: return CGSize(width: 3840, height: 2160)
        }
    }
}

// MARK: - Text Overlay Sheet

struct TextOverlaySheet: View {
    @ObservedObject var state: EditorState
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Form {
            Section("Text Content") {
                TextField("Enter text...", text: $state.overlayText, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section {
                Button("Add Text Layer") {
                    state.addLayer(type: .text, name: "Text")
                    if let idx = state.project.layers.indices.last {
                        state.project.layers[idx].textContent = state.overlayText
                        state.save()
                    }
                    dismiss()
                }
                .disabled(state.overlayText.isEmpty)
            }
        }
        .navigationTitle("Text Overlay")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Cancel") { dismiss() }
            }
        }
    }
}

// MARK: - Export View

struct ExportView: View {
    @ObservedObject var state: EditorState
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Form {
            Section("Export Settings") {
                LabeledContent("Canvas Size", value: "\(Int(state.project.canvasSize.width))×\(Int(state.project.canvasSize.height))")
                LabeledContent("Layers", value: "\(state.project.layers.count)")
                LabeledContent("Tracks", value: "\(state.project.timelineTracks.count)")
            }

            Section {
                if let progress = state.exportProgress {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Exporting...")
                            .font(.caption.bold())
                        ProgressView(value: progress)
                    }
                } else {
                    Button("Export Project") {
                        state.exportProject()
                    }
                    .frame(maxWidth: .infinity)
                    .bold()
                }

                if let error = state.exportError {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Export")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }
}

// MARK: - Asset Library View

struct AssetLibraryView: View {
    @ObservedObject var state: EditorState
    @Environment(\.dismiss) var dismiss

    var body: some View {
        List {
            Section("Templates") {
                ForEach(AssetCatalog.templates) { asset in
                    Button {
                        applyTemplate(asset)
                    } label: {
                        HStack {
                            Image(systemName: asset.icon)
                                .frame(width: 36, height: 36)
                                .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(asset.name).font(.subheadline.bold())
                                Text(asset.description).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Section("Effects") {
                ForEach(AssetCatalog.effects) { asset in
                    Button {
                        applyEffect(asset)
                    } label: {
                        HStack {
                            Image(systemName: asset.icon)
                                .frame(width: 36, height: 36)
                                .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(asset.name).font(.subheadline.bold())
                                Text(asset.description).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Section("Media") {
                ForEach(AssetCatalog.media) { asset in
                    Button {
                        applyMedia(asset)
                    } label: {
                        HStack {
                            Image(systemName: asset.icon)
                                .frame(width: 36, height: 36)
                                .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(asset.name).font(.subheadline.bold())
                                Text(asset.description).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Asset Library")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }

    private func applyTemplate(_ asset: AssetItem) {
        state.project.layers.removeAll()
        state.project.timelineTracks.removeAll()

        for config in asset.layerConfigs {
            state.addLayer(type: config.type, name: config.name)
        }

        if asset.includesTimeline {
            state.addTimelineTrack(name: "Main Track")
            for layer in state.project.layers {
                if let trackID = state.project.timelineTracks.first?.id {
                    state.assignLayerToTrack(layerID: layer.id, trackID: trackID)
                }
            }
        }

        state.save()
        dismiss()
    }

    private func applyEffect(_ asset: AssetItem) {
        guard state.selectedLayerID != nil else {
            if let firstLayer = state.project.layers.first {
                state.selectedLayerID = firstLayer.id
            } else {
                return
            }
        }
        state.applyFilter(name: asset.name, intensity: asset.effectIntensity)
    }

    private func applyMedia(_ asset: AssetItem) {
        state.addLayer(type: asset.mediaType, name: asset.name)
        dismiss()
    }
}

// MARK: - Asset Catalog

struct AssetLayerConfig {
    let type: LayerType
    let name: String
}

struct AssetItem: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let category: AssetCategory

    var layerConfigs: [AssetLayerConfig] = []
    var includesTimeline = false
    var effectIntensity: Double = 0.7
    var mediaType: LayerType = .image

    enum AssetCategory {
        case template, effect, media
    }
}

enum AssetCatalog {
    static let templates: [AssetItem] = [
        AssetItem(
            name: "Cinematic Intro",
            description: "Title card with background and overlay",
            icon: "film",
            category: .template,
            layerConfigs: [
                AssetLayerConfig(type: .image, name: "Background"),
                AssetLayerConfig(type: .text, name: "Title"),
                AssetLayerConfig(type: .shape, name: "Overlay Frame"),
            ],
            includesTimeline: true
        ),
        AssetItem(
            name: "Social Story",
            description: "Portrait layout with text and media",
            icon: "person.crop.rectangle",
            category: .template,
            layerConfigs: [
                AssetLayerConfig(type: .image, name: "Media"),
                AssetLayerConfig(type: .text, name: "Caption"),
            ]
        ),
        AssetItem(
            name: "Photo Collage",
            description: "Multi-image grid layout",
            icon: "square.grid.2x2",
            category: .template,
            layerConfigs: [
                AssetLayerConfig(type: .image, name: "Photo 1"),
                AssetLayerConfig(type: .image, name: "Photo 2"),
                AssetLayerConfig(type: .image, name: "Photo 3"),
                AssetLayerConfig(type: .image, name: "Photo 4"),
            ]
        ),
        AssetItem(
            name: "Video Montage",
            description: "Multi-clip timeline with transitions",
            icon: "rectangle.stack",
            category: .template,
            layerConfigs: [
                AssetLayerConfig(type: .video, name: "Clip 1"),
                AssetLayerConfig(type: .video, name: "Clip 2"),
                AssetLayerConfig(type: .video, name: "Clip 3"),
                AssetLayerConfig(type: .text, name: "Credits"),
            ],
            includesTimeline: true
        ),
    ]

    static let effects: [AssetItem] = [
        AssetItem(name: "Glow", description: "Soft warm glow", icon: "sun.max.fill", category: .effect, effectIntensity: 0.6),
        AssetItem(name: "Vignette", description: "Dark edges focus", icon: "circle.dashed", category: .effect, effectIntensity: 0.5),
        AssetItem(name: "Film Grain", description: "Vintage grain texture", icon: "sparkle", category: .effect, effectIntensity: 0.3),
        AssetItem(name: "Blur", description: "Gaussian blur", icon: "aqi.medium", category: .effect, effectIntensity: 0.4),
        AssetItem(name: "Color Shift", description: "Hue rotation", icon: "paintpalette.fill", category: .effect, effectIntensity: 0.5),
        AssetItem(name: "Chromatic", description: "Chromatic aberration", icon: "camera.filters", category: .effect, effectIntensity: 0.3),
    ]

    static let media: [AssetItem] = [
        AssetItem(name: "Solid Color", description: "Flat color background layer", icon: "rectangle.fill", category: .media, mediaType: .image),
        AssetItem(name: "Gradient", description: "Gradient background layer", icon: "rectangle.fill", category: .media, mediaType: .image),
        AssetItem(name: "Text Block", description: "Styled text element", icon: "textformat.abc", category: .media, mediaType: .text),
        AssetItem(name: "Rectangle", description: "Basic shape element", icon: "rectangle", category: .media, mediaType: .shape),
        AssetItem(name: "Circle", description: "Circular shape element", icon: "circle", category: .media, mediaType: .shape),
    ]
}

// MARK: - Platform Compatibility

#if os(iOS)
struct EditingEngineRepresentable: UIViewRepresentable {
    let project: EditingProject

    func makeUIView(context: Context) -> EditingEngine {
        EditingEngine(project: project)
    }

    func updateUIView(_ uiView: EditingEngine, context: Context) {
        uiView.updateProject(project)
    }
}
#else
struct EditingEngineRepresentable: View {
    let project: EditingProject
    var body: some View {
        EditingEngine()
    }
}
#endif
