import SwiftUI

struct SlideEditorView: View {
    @State var deck: SlideDeck
    @ObservedObject var manager: SlideDecksManager

    @State private var selectedSlideIndex: Int = 0
    @State private var selectedElementID: UUID? = nil
    @State private var showingPresentation = false
    @State private var showingColorPicker = false
    @State private var showingAddElement = false
    @State private var showingAddShape = false
    @State private var showingThemePicker = false
    @State private var showingLayoutPicker = false
    @State private var showingElementSheet = false
    @State private var showingAIToolsSheet = false
    @State private var showingTransitionSheet = false
    @State private var aiPrompt = ""
    @State private var aiLoading = false
    @State private var aiError: String?
    @State private var transitionBySlide: [UUID: String] = [:]

    private var selectedSlide: Slide? {
        guard selectedSlideIndex < deck.slides.count else { return nil }
        return deck.slides[selectedSlideIndex]
    }

    private var selectedElement: SlideElement? {
        guard let eid = selectedElementID,
              selectedSlideIndex < deck.slides.count else { return nil }
        return deck.slides[selectedSlideIndex].elements.first { $0.id == eid }
    }

    var body: some View {
        VStack(spacing: 0) {
            topToolbar
            Divider()
            TabView(selection: $selectedSlideIndex) {
                ForEach(Array(deck.slides.enumerated()), id: \.element.id) { idx, slide in
                    canvasArea(slide: slide)
                        .padding(12)
                        .tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            Divider()
            slideStrip
        }
        .navigationTitle(deck.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingPresentation = true
                } label: {
                    Label("Present", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .fullScreenCover(isPresented: $showingPresentation) {
            PresentationView(deck: deck)
        }
        .confirmationDialog("Add Element", isPresented: $showingAddElement) {
            Button("Text") { addElement(kind: .text) }
            Button("Shape") { showingAddShape = true }
            Button("Image Placeholder") { addElement(kind: .image) }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Add Shape", isPresented: $showingAddShape) {
            Button("Rectangle") { addShape(.rectangle) }
            Button("Circle") { addShape(.circle) }
            Button("Triangle") { addShape(.triangle) }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showingColorPicker) { backgroundColorPicker.presentationDetents([.medium]) }
        .sheet(isPresented: $showingThemePicker) { themePicker.presentationDetents([.medium]) }
        .sheet(isPresented: $showingLayoutPicker) { layoutPicker.presentationDetents([.medium]) }
        .sheet(isPresented: $showingElementSheet) { elementToolsSheet.presentationDetents([.medium]) }
        .sheet(isPresented: $showingAIToolsSheet) { aiToolsSheet.presentationDetents([.medium, .large]) }
        .sheet(isPresented: $showingTransitionSheet) { transitionSheet.presentationDetents([.medium]) }
    }

    private var topToolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                toolIcon("plus.square", label: "Add") { showingAddElement = true }
                toolIcon("rectangle.stack.badge.plus", label: "Slide") { showingLayoutPicker = true }
                toolIcon("paintpalette", label: "Background") { showingColorPicker = true }
                toolIcon("wand.and.stars", label: "Theme") { showingThemePicker = true }
                toolIcon("sparkles", label: "AI") { showingAIToolsSheet = true }
                toolIcon("arrow.left.and.right.righttriangle.left.righttriangle.right", label: "Transitions") { showingTransitionSheet = true }
                if selectedElement != nil {
                    toolIcon("slider.horizontal.3", label: "Element") { showingElementSheet = true }
                    toolIcon("doc.on.doc", label: "Duplicate") { if let el = selectedElement { duplicateElement(el) } }
                    toolIcon("trash", label: "Delete", tint: .red) { deleteSelectedElement() }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    private func toolIcon(_ icon: String, label: String, tint: Color = .blue, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.body)
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.12), in: Circle())
                .foregroundStyle(tint)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private var slideStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(deck.slides.enumerated()), id: \.element.id) { idx, slide in
                    Button {
                        selectedSlideIndex = idx
                        selectedElementID = nil
                    } label: {
                        VStack(spacing: 4) {
                            SlideThumbnailView(slide: slide)
                                .frame(width: 86, height: 52)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(selectedSlideIndex == idx ? Color.blue : Color.clear, lineWidth: 2)
                                )
                            Text("\(idx + 1)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button { duplicateSlide(at: idx) } label: { Label("Duplicate", systemImage: "doc.on.doc") }
                        Button(role: .destructive) { deleteSlide(at: idx) } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    private func canvasArea(slide: Slide) -> some View {
        GeometryReader { geo in
            ZStack {
                (Color(hex: slide.backgroundColorHex) ?? Color(red: 0.12, green: 0.23, blue: 0.37))
                    .onTapGesture { selectedElementID = nil }

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
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .background(Color(.systemGroupedBackground))
    }

    private var elementToolsSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                if let element = selectedElement {
                    Text("Element Tools")
                        .font(.headline)
                    if element.kind == .text {
                        TextField("Text", text: bindingText(element: element))
                            .textFieldStyle(.roundedBorder)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Text Size: \(Int(element.fontSize))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Slider(value: bindingFor(\.fontSize, element: element), in: 10...96)
                        }
                    }
                    Stepper("X: \(Int(element.x))", value: bindingFor(\.x, element: element), in: 0...2000, step: 10)
                    Stepper("Y: \(Int(element.y))", value: bindingFor(\.y, element: element), in: 0...2000, step: 10)
                    Stepper("Width: \(Int(element.width))", value: bindingFor(\.width, element: element), in: 20...1200, step: 10)
                    Stepper("Height: \(Int(element.height))", value: bindingFor(\.height, element: element), in: 20...800, step: 10)
                } else {
                    Text("Select an element first.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(16)
            .navigationTitle("Element")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showingElementSheet = false }
                }
            }
        }
    }

    private var aiToolsSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("AI Slide Tools")
                    .font(.headline)
                Text("Use natural language prompts. You don’t need rigid formatting.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("e.g. make this slide clearer for beginners", text: $aiPrompt, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                HStack(spacing: 8) {
                    aiQuick("Outline", icon: "list.bullet.rectangle", prompt: "Generate a concise outline for this slide.")
                    aiQuick("Speaker", icon: "person.wave.2", prompt: "Generate speaker notes for this slide.")
                    aiQuick("Visual", icon: "photo", prompt: "Suggest visual direction and concise copy.")
                }
                if aiLoading {
                    WorkspaceSkeletonLine()
                } else if let aiError {
                    Text(aiError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                Button("Apply to Current Slide", action: applyAIToSlide)
                    .buttonStyle(.borderedProminent)
                    .disabled(aiPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || aiLoading)
                Spacer()
            }
            .padding(16)
            .navigationTitle("AI Tools")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showingAIToolsSheet = false }
                }
            }
        }
    }

    private var transitionSheet: some View {
        NavigationStack {
            List {
                let styles = ["fade", "slide", "zoom", "flip", "none"]
                ForEach(styles, id: \.self) { style in
                    let selectedSlideID = selectedSlide?.id
                    Button {
                        if let selectedSlideID {
                            transitionBySlide[selectedSlideID] = style
                        }
                    } label: {
                        HStack {
                            Text(style.capitalized)
                            Spacer()
                            if let selectedSlideID, transitionBySlide[selectedSlideID] == style {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Slide Transition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showingTransitionSheet = false }
                }
            }
        }
    }

    private var backgroundColorPicker: some View {
        NavigationStack {
            List {
                let colors: [(String, String)] = [
                    ("Navy", "1E3A5F"), ("Midnight", "0B1D3A"), ("Deep Purple", "2D1B69"),
                    ("Charcoal", "2C2C2E"), ("Forest", "1B3A2A"), ("Light", "F5F5F7"), ("White", "FFFFFF")
                ]
                ForEach(colors, id: \.0) { name, hex in
                    Button {
                        updateSlideBackground(hex: hex)
                        showingColorPicker = false
                    } label: {
                        HStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(hex: hex) ?? .blue)
                                .frame(width: 30, height: 30)
                            Text(name)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Background")
        }
    }

    private var themePicker: some View {
        NavigationStack {
            let themes: [(String, String, String)] = [
                ("Ocean", "1E3A5F", "FFFFFF"), ("Forest", "1B3A2A", "FFFFFF"), ("Sunset", "7B2D1E", "FFCC00"),
                ("Minimal", "F5F5F7", "000000"), ("Night", "2D1B69", "FFFFFF")
            ]
            List {
                ForEach(themes, id: \.0) { name, bg, text in
                    Button {
                        applyTheme(background: bg, textColor: text)
                        showingThemePicker = false
                    } label: {
                        HStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: bg) ?? .blue)
                                .frame(width: 48, height: 32)
                            Text(name)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Theme")
        }
    }

    private var layoutPicker: some View {
        NavigationStack {
            let layouts: [(String, String)] = [
                ("Blank", "square"), ("Title", "text.badge.plus"), ("Content", "doc.text"),
                ("Two-Column", "rectangle.split.2x1"), ("Quote", "quote.bubble"), ("Image + Text", "photo.badge.plus")
            ]
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(layouts, id: \.0) { name, icon in
                    Button {
                        addSlideWithLayout(name)
                        showingLayoutPicker = false
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: icon).font(.title2)
                            Text(name).font(.caption.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .navigationTitle("Add Slide")
        }
    }

    private func aiQuick(_ title: String, icon: String, prompt: String) -> some View {
        Button {
            aiPrompt = prompt
        } label: {
            Image(systemName: icon)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
        }
        .buttonStyle(.bordered)
        .accessibilityLabel(title)
    }

    private func applyAIToSlide() {
        let prompt = aiPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty, selectedSlideIndex < deck.slides.count else { return }
        aiLoading = true
        aiError = nil
        Task {
            do {
                try await Task.sleep(nanoseconds: 350_000_000)
                await MainActor.run {
                    var header = SlideElement(kind: .text)
                    header.text = "AI Suggestion"
                    header.fontSize = 34
                    header.x = 240
                    header.y = 100
                    header.width = 500
                    header.textColor = "FFFFFF"

                    var body = SlideElement(kind: .text)
                    body.text = prompt
                    body.fontSize = 22
                    body.x = 220
                    body.y = 220
                    body.width = 560
                    body.height = 220
                    body.textColor = "DDDDDD"

                    deck.slides[selectedSlideIndex].elements.append(contentsOf: [header, body])
                    aiPrompt = ""
                    aiLoading = false
                    saveDeck()
                }
            } catch {
                await MainActor.run {
                    aiError = "Couldn’t apply AI this time. Natural language prompts are supported—try again."
                    aiLoading = false
                }
            }
        }
    }

    private func bindingFor(_ keyPath: WritableKeyPath<SlideElement, Double>, element: SlideElement) -> Binding<Double> {
        Binding(
            get: { selectedElement?[keyPath: keyPath] ?? element[keyPath: keyPath] },
            set: { newValue in
                updateElementProperty(element) { $0[keyPath: keyPath] = newValue }
            }
        )
    }

    private func bindingText(element: SlideElement) -> Binding<String> {
        Binding(
            get: { selectedElement?.text ?? element.text },
            set: { newValue in
                updateElementProperty(element) { $0.text = newValue }
            }
        )
    }

    private func updateElementProperty(_ element: SlideElement, update: (inout SlideElement) -> Void) {
        guard selectedSlideIndex < deck.slides.count,
              let idx = deck.slides[selectedSlideIndex].elements.firstIndex(where: { $0.id == element.id }) else { return }
        update(&deck.slides[selectedSlideIndex].elements[idx])
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

    private func addSlideWithLayout(_ layout: String) {
        var slide = Slide.blank(title: "Slide \(deck.slides.count + 1)")
        switch layout {
        case "Title":
            var titleEl = SlideElement(kind: .text)
            titleEl.text = "Title"; titleEl.fontSize = 48
            titleEl.x = 200; titleEl.y = 150; titleEl.width = 560; titleEl.height = 80
            var subtitleEl = SlideElement(kind: .text)
            subtitleEl.text = "Subtitle"; subtitleEl.fontSize = 28
            subtitleEl.x = 200; subtitleEl.y = 260; subtitleEl.width = 560; subtitleEl.height = 50
            subtitleEl.textColor = "CCCCCC"
            slide.elements = [titleEl, subtitleEl]
        case "Content":
            var titleEl = SlideElement(kind: .text)
            titleEl.text = "Title"; titleEl.fontSize = 36
            titleEl.x = 50; titleEl.y = 60; titleEl.width = 860; titleEl.height = 60
            var bodyEl = SlideElement(kind: .text)
            bodyEl.text = "Content goes here"; bodyEl.fontSize = 22
            bodyEl.x = 50; bodyEl.y = 150; bodyEl.width = 860; bodyEl.height = 200
            bodyEl.textColor = "DDDDDD"
            slide.elements = [titleEl, bodyEl]
        case "Quote":
            var quoteEl = SlideElement(kind: .text)
            quoteEl.text = "\"Your quote here\""; quoteEl.fontSize = 32
            quoteEl.x = 80; quoteEl.y = 160; quoteEl.width = 800; quoteEl.height = 100
            quoteEl.textColor = "FFFFFF"; quoteEl.textAlignment = "center"
            slide.elements = [quoteEl]
        default:
            break
        }
        deck.slides.append(slide)
        selectedSlideIndex = deck.slides.count - 1
        selectedElementID = nil
        saveDeck()
    }

    private func addElement(kind: SlideElement.ElementKind) {
        guard selectedSlideIndex < deck.slides.count else { return }
        var el = SlideElement(kind: kind)
        el.x = 200; el.y = 200
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

    private func addShape(_ kind: SlideElement.ShapeKind) {
        guard selectedSlideIndex < deck.slides.count else { return }
        var el = SlideElement(kind: .shape)
        el.shapeKind = kind
        el.x = 200; el.y = 200; el.width = 120; el.height = 80; el.fillColor = "3B82F6"
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

    private func duplicateElement(_ element: SlideElement) {
        guard selectedSlideIndex < deck.slides.count else { return }
        var copy = element
        copy.id = UUID()
        copy.x += 20; copy.y += 20
        deck.slides[selectedSlideIndex].elements.append(copy)
        selectedElementID = copy.id
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

    private func applyTheme(background: String, textColor: String) {
        for idx in deck.slides.indices {
            deck.slides[idx].backgroundColorHex = background
            for elIdx in deck.slides[idx].elements.indices where deck.slides[idx].elements[elIdx].kind == .text {
                deck.slides[idx].elements[elIdx].textColor = textColor
            }
        }
        saveDeck()
    }

    private func saveDeck() {
        manager.updateDeck(deck)
    }
}

private struct CanvasElementView: View {
    let element: SlideElement
    let isSelected: Bool
    let onSelect: () -> Void
    let onUpdate: (SlideElement) -> Void

    @State private var dragOffset: CGSize = .zero

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
                .onChanged { value in dragOffset = value.translation }
                .onEnded { value in
                    var updated = element
                    updated.x += value.translation.width
                    updated.y += value.translation.height
                    dragOffset = .zero
                    onUpdate(updated)
                }
        )
        .onTapGesture { onSelect() }
    }

    @ViewBuilder
    private var elementContent: some View {
        switch element.kind {
        case .text:
            Text(element.text)
                .font(.system(size: element.fontSize, weight: element.fontWeight == "bold" ? .bold : .regular))
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
