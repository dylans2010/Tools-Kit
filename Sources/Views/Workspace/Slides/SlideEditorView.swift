import SwiftUI

struct SlideEditorView: View {
    @State var deck: SlideDeck
    @ObservedObject var manager: SlideDecksManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedSlideIndex: Int = 0
    @State private var selectedElementID: UUID? = nil
    @State private var showingPresentation = false
    @State private var showingColorPicker = false
    @State private var showingAddElement = false
    @State private var showingImagePicker = false

    private var selectedSlide: Slide? {
        guard selectedSlideIndex < deck.slides.count else { return nil }
        return deck.slides[selectedSlideIndex]
    }

    var body: some View {
        HStack(spacing: 0) {
            // Slide list sidebar
            slideListSidebar
                .frame(width: 100)
                .background(Color(.secondarySystemBackground))

            Divider()

            // Canvas
            VStack(spacing: 0) {
                canvasToolbar
                Divider()
                if let slide = selectedSlide {
                    canvasArea(slide: slide)
                } else {
                    Spacer()
                }
            }
        }
        .navigationTitle(deck.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button {
                        showingPresentation = true
                    } label: {
                        Label("Present", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
        }
        .fullScreenCover(isPresented: $showingPresentation) {
            PresentationView(deck: deck)
        }
        .confirmationDialog("Add Element", isPresented: $showingAddElement) {
            Button("Text") { addElement(kind: .text) }
            Button("Shape") { addElement(kind: .shape) }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Sidebar

    private var slideListSidebar: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(Array(deck.slides.enumerated()), id: \.element.id) { idx, slide in
                        Button {
                            selectedSlideIndex = idx
                            selectedElementID = nil
                        } label: {
                            VStack(spacing: 4) {
                                SlideThumbnailView(slide: slide)
                                    .frame(width: 80, height: 50)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(selectedSlideIndex == idx ? Color.blue : Color.clear, lineWidth: 2)
                                    )
                                Text("\(idx + 1)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                deleteSlide(at: idx)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button {
                                duplicateSlide(at: idx)
                            } label: {
                                Label("Duplicate", systemImage: "doc.on.doc")
                            }
                        }
                    }
                }
                .padding(8)
            }

            Divider()

            Button {
                addSlide()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .padding(10)
            }
        }
    }

    // MARK: - Canvas toolbar

    private var canvasToolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                toolbarButton("Add Element", icon: "plus.square") {
                    showingAddElement = true
                }

                if selectedElementID != nil {
                    toolbarButton("Delete", icon: "trash", tint: .red) {
                        deleteSelectedElement()
                    }
                }

                toolbarButton("Background", icon: "paintpalette") {
                    showingColorPicker = true
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .sheet(isPresented: $showingColorPicker) {
            backgroundColorPicker
        }
    }

    private func toolbarButton(_ title: String, icon: String, tint: Color = .blue, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.body)
                Text(title)
                    .font(.caption2)
            }
            .foregroundColor(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Canvas

    private func canvasArea(slide: Slide) -> some View {
        GeometryReader { geo in
            ZStack {
                (Color(hex: slide.backgroundColorHex) ?? Color(red: 0.12, green: 0.23, blue: 0.37))
                    .onTapGesture {
                        selectedElementID = nil
                    }

                ForEach(slide.elements) { element in
                    CanvasElementView(
                        element: element,
                        isSelected: selectedElementID == element.id,
                        onSelect: { selectedElementID = element.id },
                        onUpdate: { updated in updateElement(updated) }
                    )
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Background Color Picker

    private var backgroundColorPicker: some View {
        NavigationStack {
            List {
                let colors: [(String, String)] = [
                    ("Navy", "1E3A5F"), ("Midnight Blue", "0B1D3A"), ("Dark Teal", "0D3B4E"),
                    ("Deep Purple", "2D1B69"), ("Charcoal", "2C2C2E"), ("Forest", "1B3A2A"),
                    ("Rust", "7B2D1E"), ("Light", "F5F5F7"), ("White", "FFFFFF")
                ]
                ForEach(colors, id: \.0) { name, hex in
                    Button {
                        updateSlideBackground(hex: hex)
                        showingColorPicker = false
                    } label: {
                        HStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(hex: hex) ?? .blue)
                                .frame(width: 32, height: 32)
                            Text(name)
                            Spacer()
                            if deck.slides[safe: selectedSlideIndex]?.backgroundColorHex == hex {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Background Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showingColorPicker = false }
                }
            }
        }
    }

    // MARK: - Actions

    private func addSlide() {
        let slide = Slide.blank(title: "Slide \(deck.slides.count + 1)")
        deck.slides.append(slide)
        selectedSlideIndex = deck.slides.count - 1
        selectedElementID = nil
        saveDeck()
    }

    private func deleteSlide(at idx: Int) {
        guard deck.slides.count > 1 else { return }
        deck.slides.remove(at: idx)
        selectedSlideIndex = max(0, min(selectedSlideIndex, deck.slides.count - 1))
        saveDeck()
    }

    private func duplicateSlide(at idx: Int) {
        var copy = deck.slides[idx]
        copy.id = UUID()
        deck.slides.insert(copy, at: idx + 1)
        selectedSlideIndex = idx + 1
        saveDeck()
    }

    private func addElement(kind: SlideElement.ElementKind) {
        guard selectedSlideIndex < deck.slides.count else { return }
        var el = SlideElement(kind: kind)
        el.x = 200
        el.y = 200
        switch kind {
        case .text:
            el.width = 240; el.height = 60; el.text = "New Text"; el.textColor = "FFFFFF"; el.fontSize = 28
        case .image:
            el.width = 200; el.height = 150
        case .shape:
            el.width = 120; el.height = 80; el.fillColor = "3B82F6"
        }
        deck.slides[selectedSlideIndex].elements.append(el)
        selectedElementID = el.id
        saveDeck()
    }

    private func deleteSelectedElement() {
        guard let eid = selectedElementID, selectedSlideIndex < deck.slides.count else { return }
        deck.slides[selectedSlideIndex].elements.removeAll { $0.id == eid }
        selectedElementID = nil
        saveDeck()
    }

    private func updateElement(_ updated: SlideElement) {
        guard selectedSlideIndex < deck.slides.count else { return }
        if let idx = deck.slides[selectedSlideIndex].elements.firstIndex(where: { $0.id == updated.id }) {
            deck.slides[selectedSlideIndex].elements[idx] = updated
        }
        saveDeck()
    }

    private func updateSlideBackground(hex: String) {
        guard selectedSlideIndex < deck.slides.count else { return }
        deck.slides[selectedSlideIndex].backgroundColorHex = hex
        saveDeck()
    }

    private func saveDeck() {
        manager.updateDeck(deck)
    }
}

// MARK: - Canvas Element View

private struct CanvasElementView: View {
    let element: SlideElement
    let isSelected: Bool
    let onSelect: () -> Void
    let onUpdate: (SlideElement) -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var showingEdit = false

    var body: some View {
        ZStack {
            elementContent

            if isSelected {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.blue, lineWidth: 2)
                    .frame(width: element.width + 8, height: element.height + 8)
            }
        }
        .position(x: element.x + dragOffset.width, y: element.y + dragOffset.height)
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { value in
                    var updated = element
                    updated.x += value.translation.width
                    updated.y += value.translation.height
                    dragOffset = .zero
                    onUpdate(updated)
                }
        )
        .onTapGesture {
            onSelect()
        }
        .onLongPressGesture {
            onSelect()
            showingEdit = true
        }
        .sheet(isPresented: $showingEdit) {
            ElementEditSheet(element: element, onSave: onUpdate)
        }
    }

    @ViewBuilder
    private var elementContent: some View {
        switch element.kind {
        case .text:
            Text(element.text)
                .font(.system(size: element.fontSize))
                .foregroundColor(Color(hex: element.textColor) ?? .white)
                .multilineTextAlignment(textAlignment)
                .frame(width: element.width, height: element.height)

        case .image:
            if let data = element.imageData, let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: element.width, height: element.height)
                    .clipped()
            } else {
                ZStack {
                    Color.gray.opacity(0.3)
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(width: element.width, height: element.height)
                .cornerRadius(8)
            }

        case .shape:
            shapeView
        }
    }

    private var textAlignment: TextAlignment {
        switch element.textAlignment {
        case "leading": return .leading
        case "trailing": return .trailing
        default: return .center
        }
    }

    @ViewBuilder
    private var shapeView: some View {
        let fill = Color(hex: element.fillColor) ?? .blue
        switch element.shapeKind {
        case .rectangle:
            RoundedRectangle(cornerRadius: element.cornerRadius)
                .fill(fill)
                .frame(width: element.width, height: element.height)
        case .circle:
            Circle()
                .fill(fill)
                .frame(width: element.width, height: element.height)
        case .triangle:
            TriangleShape()
                .fill(fill)
                .frame(width: element.width, height: element.height)
        }
    }
}

// MARK: - Element Edit Sheet

private struct ElementEditSheet: View {
    @State var element: SlideElement
    let onSave: (SlideElement) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                if element.kind == .text {
                    Section("Text") {
                        TextField("Content", text: $element.text)
                        Stepper("Font size: \(Int(element.fontSize))", value: $element.fontSize, in: 8...120, step: 2)
                    }
                    Section("Layout") {
                        Stepper("Width: \(Int(element.width))", value: $element.width, in: 40...800, step: 10)
                        Stepper("Height: \(Int(element.height))", value: $element.height, in: 20...600, step: 10)
                    }
                }
                if element.kind == .shape {
                    Section("Shape") {
                        Picker("Kind", selection: $element.shapeKind) {
                            ForEach(SlideElement.ShapeKind.allCases, id: \.self) {
                                Text($0.displayName).tag($0)
                            }
                        }
                        Stepper("Width: \(Int(element.width))", value: $element.width, in: 20...800, step: 10)
                        Stepper("Height: \(Int(element.height))", value: $element.height, in: 20...600, step: 10)
                        Stepper("Corner Radius: \(Int(element.cornerRadius))", value: $element.cornerRadius, in: 0...60, step: 4)
                    }
                }
                Section("Position") {
                    Stepper("X: \(Int(element.x))", value: $element.x, in: 0...800, step: 10)
                    Stepper("Y: \(Int(element.y))", value: $element.y, in: 0...1200, step: 10)
                }
            }
            .navigationTitle("Edit Element")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onSave(element)
                        dismiss()
                    }
                    .bold()
                }
            }
        }
    }
}

// MARK: - Safe subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
