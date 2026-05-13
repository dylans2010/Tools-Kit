import SwiftUI
import PhotosUI
#if canImport(ImagePlayground)
import ImagePlayground
#endif

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
    @State private var showingSlideToolsSheet = false
    @State private var showingImagePlayground = false
    @State private var showingGrid = false
    @State private var showingUnsplash = false
    @State private var snapToGrid = true
    @State private var aiPrompt = ""
    @State private var aiLoading = false
    @State private var aiError: String?
    @State private var transitionBySlide: [UUID: String] = [:]
    @State private var photoPickerItem: PhotosPickerItem?
    private let gridSnapSize: Double = 10
    private let defaultCanvasCenter = CGPoint(x: 500, y: 280)

    private var selectedSlide: Slide? {
        guard selectedSlideIndex < deck.slides.count else { return nil }
        return deck.slides[selectedSlideIndex]
    }

    private var selectedElement: SlideElement? {
        guard let eid = selectedElementID,
              selectedSlideIndex < deck.slides.count else { return nil }
        return deck.slides[selectedSlideIndex].elements.first { $0.id == eid }
    }

    private var currentSlideSummary: String {
        guard let slide = selectedSlide else { return "No active slide." }
        let textSnippets = slide.elements.filter { $0.kind == .text }.map(\.text).joined(separator: " | ")
        return "Title: \(slide.title)\nText: \(textSnippets)\nElement count: \(slide.elements.count)"
    }

    var body: some View {
        VStack(spacing: 0) {
            modernTopToolbar
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
            ToolbarItemGroup(placement: .topBarTrailing) {
                PhotosPicker(selection: $photoPickerItem, matching: .images) {
                    Image(systemName: "photo.on.rectangle")
                }
                .accessibilityLabel("Upload background image")

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
            Button("Unsplash Image") { showingUnsplash = true }
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
        .sheet(isPresented: $showingElementSheet) { elementToolsSheet.presentationDetents([.medium, .large]) }
        .sheet(isPresented: $showingAIToolsSheet) { aiToolsSheet.presentationDetents([.medium, .large]) }
        .sheet(isPresented: $showingTransitionSheet) { transitionSheet.presentationDetents([.medium]) }
        .sheet(isPresented: $showingSlideToolsSheet) { slideToolsSheet.presentationDetents([.medium]) }
        .sheet(isPresented: $showingUnsplash) {
            UnsplashImagesView { photo in
                insertUnsplashImage(photo)
            }
        }
        .modifier(ImagePlaygroundSlideModifier(
            isPresented: $showingImagePlayground,
            concept: imagePlaygroundConcept,
            onResult: { url in
                if let data = try? Data(contentsOf: url) {
                    setBackgroundImageData(data)
                }
            }
        ))
        .onChange(of: photoPickerItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        setBackgroundImageData(data)
                    }
                }
            }
        }
    }

    private var modernTopToolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                toolIcon("plus.square", label: "Add Element") { showingAddElement = true }
                toolIcon("rectangle.stack.badge.plus", label: "Add Slide") { showingLayoutPicker = true }
                toolIcon("doc.on.doc", label: "Duplicate Slide") { duplicateCurrentSlide() }
                toolIcon("arrow.left.arrow.right", label: "Move Slide") { showingSlideToolsSheet = true }
                toolIcon("paintpalette", label: "Background") { showingColorPicker = true }
                toolIcon("wand.and.stars", label: "Theme") { showingThemePicker = true }
                toolIcon("rectangle.dashed", label: "Grid") { showingGrid.toggle() }
                toolIcon("scope", label: "Snap") { snapToGrid.toggle() }
                toolIcon("sparkles", label: "AI") { showingAIToolsSheet = true }
                toolIcon("arrow.triangle.2.circlepath", label: "Transitions") { showingTransitionSheet = true }
                if supportsImagePlayground {
                    toolIcon("photo.artframe", label: "Playground") { showingImagePlayground = true }
                }
                toolIcon("trash.slash", label: "Clear BG") { clearSlideBackgroundImage() }
                if selectedElement != nil {
                    toolIcon("slider.horizontal.3", label: "Element Tools") { showingElementSheet = true }
                    toolIcon("character.cursor.ibeam", label: "Bold") { toggleSelectedTextBold() }
                    toolIcon("text.alignleft", label: "Align Left") { setTextAlignment("leading") }
                    toolIcon("text.aligncenter", label: "Align Center") { setTextAlignment("center") }
                    toolIcon("text.alignright", label: "Align Right") { setTextAlignment("trailing") }
                    toolIcon("arrow.up.to.line", label: "Bring Front") { bringSelectedElementToFront() }
                    toolIcon("arrow.down.to.line", label: "Send Back") { sendSelectedElementToBack() }
                    toolIcon("plus.square.on.square", label: "Duplicate Element") { if let el = selectedElement { duplicateElement(el) } }
                    toolIcon("trash", label: "Delete Element", tint: .red) { deleteSelectedElement() }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(.ultraThinMaterial)
    }

    private func toolIcon(_ icon: String, label: String, tint: Color = .blue, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.body.weight(.semibold))
                    .frame(width: 36, height: 36)
                    .background(tint.opacity(0.14), in: Circle())
                    .foregroundStyle(tint)
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
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
                                .frame(width: 92, height: 56)
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
                        Button { moveSlide(at: idx, by: -1) } label: { Label("Move Left", systemImage: "arrow.left") }
                        Button { moveSlide(at: idx, by: 1) } label: { Label("Move Right", systemImage: "arrow.right") }
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
                slideBackgroundView(for: slide)
                    .onTapGesture { selectedElementID = nil }

                if showingGrid {
                    canvasGrid
                }

                ForEach(slide.elements) { element in
                    SlideCanvasElementView(
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

    @ViewBuilder
    private func slideBackgroundView(for slide: Slide) -> some View {
        if let data = slide.backgroundImageData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            (Color(hex: slide.backgroundColorHex), green: 0.23, blue: 0.37))
        }
    }

    private var canvasGrid: some View {
        GeometryReader { proxy in
            Path { path in
                let step: CGFloat = 24
                var x: CGFloat = 0
                while x <= proxy.size.width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: proxy.size.height))
                    x += step
                }
                var y: CGFloat = 0
                while y <= proxy.size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: proxy.size.width, y: y))
                    y += step
                }
            }
            .stroke(Color.white.opacity(0.17), lineWidth: 0.5)
        }
    }

    private var slideToolsSheet: some View {
        NavigationStack {
            Form {
                Section {
                    Button("Duplicate Current Slide", action: duplicateCurrentSlide)
                    Button("Move Slide Left") { moveSlide(at: selectedSlideIndex, by: -1) }
                    Button("Move Slide Right") { moveSlide(at: selectedSlideIndex, by: 1) }
                    Button("Delete Current Slide", role: .destructive) { deleteSlide(at: selectedSlideIndex) }
                } header: {
                    Text("Slide Actions")
                }

                Section {
                    Button("Add Title + Body Block") { addSlideWithLayout("Content") }
                    Button("Add Quote Layout") { addSlideWithLayout("Quote") }
                    Button("Add Agenda Slide") { addSlideWithLayout("Agenda") }
                    Button("Add Comparison Slide") { addSlideWithLayout("Comparison") }
                    Button("Add Checklist Slide") { addSlideWithLayout("Checklist") }
                    Button("Add Closing Slide") { addSlideWithLayout("Closing") }
                    Button("Add Callout Slide") { addSlideWithLayout("Callout") }
                    Button("Center Selected Element") { centerSelectedElement() }
                    Button("Nudge Up") { nudgeSelectedElement(dx: 0, dy: -10) }
                    Button("Nudge Down") { nudgeSelectedElement(dx: 0, dy: 10) }
                    Button("Nudge Left") { nudgeSelectedElement(dx: -10, dy: 0) }
                    Button("Nudge Right") { nudgeSelectedElement(dx: 10, dy: 0) }
                } header: {
                    Text("Smart Layout Helpers")
                }

                Section {
                    Button("Randomize Color") { randomizeBackgroundColor() }
                    if supportsImagePlayground {
                        Button("Generate with Image Playground") { showingImagePlayground = true }
                    }
                    Button("Clear Background Image") { clearSlideBackgroundImage() }
                } header: {
                    Text("Background Tools")
                }
            }
            .navigationTitle("Slide Tools")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showingSlideToolsSheet = false }
                }
            }
        }
    }

    private var elementToolsSheet: some View {
        NavigationStack {
            Form {
                if let element = selectedElement {
                    Section {
                        Stepper("X: \(Int(element.x))", value: bindingFor(\.x, element: element), in: 0...2000, step: 10)
                        Stepper("Y: \(Int(element.y))", value: bindingFor(\.y, element: element), in: 0...2000, step: 10)
                        Stepper("Width: \(Int(element.width))", value: bindingFor(\.width, element: element), in: 20...1600, step: 10)
                        Stepper("Height: \(Int(element.height))", value: bindingFor(\.height, element: element), in: 20...1200, step: 10)
                    } header: {
                        Text("Position & Size")
                    }

                    if element.kind == .text {
                        Section {
                            TextField("Text", text: bindingText(element: element), axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .skillPicker(text: bindingText(element: element))
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Font Size: \(Int(element.fontSize))")
                                    .font(.caption)
                                Slider(value: bindingFor(\.fontSize, element: element), in: 10...120, step: 1)
                            }
                            Toggle("Bold", isOn: Binding(
                                get: { (selectedElement?.fontWeight ?? element.fontWeight) == "bold" },
                                set: { isBold in
                                    updateElementProperty(element) { $0.fontWeight = isBold ? "bold" : "regular" }
                                }
                            ))
                        } header: {
                            Text("Text")
                        }
                    }

                    if element.kind == .shape {
                        Section {
                            Stepper("Corner Radius: \(Int(element.cornerRadius))", value: bindingFor(\.cornerRadius, element: element), in: 0...60, step: 1)
                            Stepper("Stroke Width: \(Int(element.strokeWidth))", value: bindingFor(\.strokeWidth, element: element), in: 0...20, step: 1)
                        } header: {
                            Text("Shape")
                        }
                    }
                } else {
                    Text("Select an element first.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Element Tools")
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
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("AI Slide Studio")
                        .font(.headline)
                    Text("Use natural language prompts. AI can rewrite copy, generate structure, and draft new slides.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    TextField("e.g. Make this slide simpler for executives", text: $aiPrompt, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .skillPicker(text: $aiPrompt)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        aiQuick("Outline", icon: "list.bullet.rectangle", prompt: "Generate a concise slide outline with 3-5 bullets.")
                        aiQuick("Speaker Notes", icon: "person.wave.2", prompt: "Generate speaker notes for this slide.")
                        aiQuick("Simplify", icon: "textformat.size.smaller", prompt: "Rewrite this slide in simple plain language.")
                        aiQuick("Executive", icon: "briefcase", prompt: "Rewrite this slide for executive audience in concise bullets.")
                        aiQuick("Action Items", icon: "checklist", prompt: "Extract action items with owner placeholders.")
                        aiQuick("Visual Ideas", icon: "photo", prompt: "Suggest visual concept and short caption options.")
                        aiQuick("Q&A", icon: "questionmark.bubble", prompt: "Create likely Q&A with concise answers.")
                        aiQuick("Timeline", icon: "calendar", prompt: "Convert this content into timeline format.")
                        aiQuick("Agenda", icon: "list.number", prompt: "Turn this slide into an agenda with timing hints.")
                        aiQuick("Comparison", icon: "rectangle.split.3x1", prompt: "Rewrite this slide as a comparison table or side-by-side structure.")
                        aiQuick("Brand Voice", icon: "paintbrush", prompt: "Rewrite this slide to sound more on-brand and polished.")
                        aiQuick("Story", icon: "sparkles", prompt: "Rewrite this slide as a short storytelling arc with a hook and payoff.")
                    }

                    if aiLoading {
                        WorkspaceSkeletonLine()
                    } else if let aiError {
                        Text(aiError)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    HStack(spacing: 8) {
                        Button("Apply to Current Slide") {
                            generateAIContent(createNewSlide: false)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(aiPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || aiLoading)

                        Button("Create New AI Slide") {
                            generateAIContent(createNewSlide: true)
                        }
                        .buttonStyle(.bordered)
                        .disabled(aiPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || aiLoading)
                    }
                }
                .padding(16)
            }
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
                let styles = ["fade", "slide", "zoom", "flip", "none", "push", "dissolve"]
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
                    ("Charcoal", "2C2C2E"), ("Forest", "1B3A2A"), ("Light", "F5F5F7"), ("White", "FFFFFF"),
                    ("Emerald", "047857"), ("Rose", "BE185D"), ("Sky", "0EA5E9")
                ]
                ForEach(colors, id: \.0) { name, hex in
                    Button {
                        updateSlideBackground(hex: hex)
                        showingColorPicker = false
                    } label: {
                        HStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(hex: hex))
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
                ("Minimal", "F5F5F7", "000000"), ("Night", "2D1B69", "FFFFFF"), ("Neon", "0F172A", "22D3EE")
            ]
            List {
                ForEach(themes, id: \.0) { name, bg, text in
                    Button {
                        applyTheme(background: bg, textColor: text)
                        showingThemePicker = false
                    } label: {
                        HStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: bg))
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
                ("Two-Column", "rectangle.split.2x1"), ("Quote", "quote.bubble"), ("Image + Text", "photo.badge.plus"),
                ("Agenda", "list.bullet.clipboard"), ("Metrics", "chart.bar")
            ]
            ScrollView {
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
            }
            .navigationTitle("Add Slide")
        }
    }

    private func aiQuick(_ title: String, icon: String, prompt: String) -> some View {
        Button {
            aiPrompt = prompt
        } label: {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 9)
        }
        .buttonStyle(.bordered)
        .accessibilityLabel(title)
    }

    private func generateAIContent(createNewSlide: Bool) {
        let prompt = aiPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty, selectedSlideIndex < deck.slides.count else { return }
        aiLoading = true
        aiError = nil
        Task {
            do {
                let fullPrompt = """
                You are helping edit a presentation slide.
                Current slide context:
                \(currentSlideSummary)

                User request:
                \(prompt)

                Return concise plain text with clear headings and bullet points.
                """
                let response = try await AIService.shared.processText(
                    prompt: fullPrompt,
                    systemPrompt: "You are a presentation assistant focused on concise slide-ready content."
                )
                await MainActor.run {
                    insertAIResponse(response, createNewSlide: createNewSlide)
                    aiPrompt = ""
                    aiLoading = false
                }
            } catch {
                await MainActor.run {
                    aiError = "Couldn’t generate AI slide content. Try again with a shorter prompt."
                    aiLoading = false
                }
            }
        }
    }

    private func insertAIResponse(_ response: String, createNewSlide: Bool) {
        var targetIndex = selectedSlideIndex
        if createNewSlide {
            let newSlide = Slide.blank(title: "AI Slide \(deck.slides.count + 1)")
            deck.slides.append(newSlide)
            targetIndex = deck.slides.count - 1
            selectedSlideIndex = targetIndex
        }

        var header = SlideElement(kind: .text)
        header.text = "AI Suggestion"
        header.fontSize = 34
        header.fontWeight = "bold"
        header.x = 240
        header.y = 100
        header.width = 500
        header.textColor = "FFFFFF"

        var body = SlideElement(kind: .text)
        body.text = response
        body.fontSize = 22
        body.x = 220
        body.y = 220
        body.width = 560
        body.height = 260
        body.textColor = "DDDDDD"
        body.textAlignment = "leading"

        deck.slides[targetIndex].elements.append(contentsOf: [header, body])
        saveDeck()
    }

    private func bindingFor(_ keyPath: WritableKeyPath<SlideElement, Double>, element: SlideElement) -> Binding<Double> {
        Binding(
            get: { selectedElement?[keyPath: keyPath] ?? element[keyPath: keyPath] },
            set: { newValue in
                updateElementProperty(element) { current in
                    current[keyPath: keyPath] = newValue
                }
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

    private func moveSlide(at idx: Int, by delta: Int) {
        let target = idx + delta
        guard deck.slides.indices.contains(idx), deck.slides.indices.contains(target) else { return }
        let moving = deck.slides.remove(at: idx)
        deck.slides.insert(moving, at: target)
        selectedSlideIndex = target
        saveDeck()
    }

    private func deleteSlide(at idx: Int) {
        guard deck.slides.count > 1, deck.slides.indices.contains(idx) else { return }
        deck.slides.remove(at: idx)
        selectedSlideIndex = max(0, min(selectedSlideIndex, deck.slides.count - 1))
        saveDeck()
    }

    private func duplicateSlide(at idx: Int) {
        guard deck.slides.indices.contains(idx) else { return }
        var copy = deck.slides[idx]
        copy.id = UUID()
        copy.title = "\(copy.title) Copy"
        deck.slides.insert(copy, at: idx + 1)
        selectedSlideIndex = idx + 1
        saveDeck()
    }

    private func duplicateCurrentSlide() {
        duplicateSlide(at: selectedSlideIndex)
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
            bodyEl.textColor = "DDDDDD"; bodyEl.textAlignment = "leading"
            slide.elements = [titleEl, bodyEl]
        case "Quote":
            var quoteEl = SlideElement(kind: .text)
            quoteEl.text = "\"Your quote here\""; quoteEl.fontSize = 32
            quoteEl.x = 80; quoteEl.y = 160; quoteEl.width = 800; quoteEl.height = 100
            quoteEl.textColor = "FFFFFF"; quoteEl.textAlignment = "center"
            slide.elements = [quoteEl]
        case "Two-Column":
            var left = SlideElement(kind: .text)
            left.text = "Left column"; left.fontSize = 24
            left.x = 250; left.y = 220; left.width = 360; left.height = 280
            left.textAlignment = "leading"
            var right = SlideElement(kind: .text)
            right.text = "Right column"; right.fontSize = 24
            right.x = 700; right.y = 220; right.width = 360; right.height = 280
            right.textAlignment = "leading"
            slide.elements = [left, right]
        case "Image + Text":
            var image = SlideElement(kind: .image)
            image.x = 260; image.y = 250; image.width = 420; image.height = 300
            var text = SlideElement(kind: .text)
            text.text = "Describe the visual"; text.fontSize = 26
            text.x = 710; text.y = 250; text.width = 320; text.height = 260
            text.textAlignment = "leading"
            slide.elements = [image, text]
        case "Agenda":
            var titleEl = SlideElement(kind: .text)
            titleEl.text = "Agenda"; titleEl.fontSize = 42
            titleEl.x = 200; titleEl.y = 90; titleEl.width = 560; titleEl.height = 70
            var agenda = SlideElement(kind: .text)
            agenda.text = "1. Intro\n2. Problem\n3. Solution\n4. Next Steps"
            agenda.fontSize = 24
            agenda.x = 260; agenda.y = 240; agenda.width = 620; agenda.height = 280
            agenda.textAlignment = "leading"
            slide.elements = [titleEl, agenda]
        case "Metrics":
            var titleEl = SlideElement(kind: .text)
            titleEl.text = "Key Metrics"; titleEl.fontSize = 40
            titleEl.x = 220; titleEl.y = 90; titleEl.width = 560; titleEl.height = 70
            var metric1 = SlideElement(kind: .shape)
            metric1.shapeKind = .rectangle
            metric1.fillColor = "1D4ED8"
            metric1.x = 220; metric1.y = 240; metric1.width = 240; metric1.height = 140
            var metric2 = SlideElement(kind: .shape)
            metric2.shapeKind = .rectangle
            metric2.fillColor = "047857"
            metric2.x = 500; metric2.y = 240; metric2.width = 240; metric2.height = 140
            slide.elements = [titleEl, metric1, metric2]
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
        case .text, .bullets:
            el.width = 280; el.height = 80; el.text = "New Text"; el.textColor = "FFFFFF"; el.fontSize = 28
        case .image:
            el.width = 260; el.height = 180
        case .chart:
            el.width = 320; el.height = 220
            el.chartData = SlideElement.ChartData(title: "Chart", labels: ["A", "B", "C"], values: [40, 30, 20])
        case .shape:
            el.width = 140; el.height = 100; el.fillColor = "3B82F6"
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
            var normalized = updated
            if snapToGrid {
                normalized.x = snapValue(normalized.x)
                normalized.y = snapValue(normalized.y)
            }
            deck.slides[selectedSlideIndex].elements[idx] = normalized
        }
        saveDeck()
    }

    private func snapValue(_ value: Double) -> Double {
        guard snapToGrid else { return value }
        return (value / gridSnapSize).rounded() * gridSnapSize
    }

    private func updateSlideBackground(hex: String) {
        guard selectedSlideIndex < deck.slides.count else { return }
        deck.slides[selectedSlideIndex].backgroundColorHex = hex
        saveDeck()
    }

    private func insertUnsplashImage(_ photo: UnsplashPhoto) {
        guard selectedSlideIndex < deck.slides.count else { return }
        Task {
            let result = await UnsplashProvider.shared.downloadImageData(from: photo, quality: .regular)
            await MainActor.run {
                switch result {
                case .success(let data):
                    var el = SlideElement(kind: .image)
                    el.imageData = data
                    el.imageURL = URL(string: photo.urls.regular)
                    el.caption = "Photo by \(photo.user.name) on Unsplash"
                    el.x = 200; el.y = 200
                    let aspectRatio = Double(photo.width) / max(Double(photo.height), 1)
                    el.width = 300
                    el.height = 300 / aspectRatio
                    deck.slides[selectedSlideIndex].elements.append(el)
                    selectedElementID = el.id
                    saveDeck()
                case .failure:
                    break
                }
            }
        }
    }

    private func setBackgroundImageData(_ data: Data) {
        guard selectedSlideIndex < deck.slides.count else { return }
        deck.slides[selectedSlideIndex].backgroundImageData = data
        saveDeck()
    }

    private func clearSlideBackgroundImage() {
        guard selectedSlideIndex < deck.slides.count else { return }
        deck.slides[selectedSlideIndex].backgroundImageData = nil
        saveDeck()
    }

    private func randomizeBackgroundColor() {
        let colors = ["1E3A5F", "334155", "7C3AED", "0F766E", "1D4ED8", "BE185D", "374151", "047857"]
        updateSlideBackground(hex: colors.randomElement() ?? "1E3A5F")
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

    private func toggleSelectedTextBold() {
        guard let element = selectedElement, element.kind == .text else { return }
        updateElementProperty(element) { current in
            current.fontWeight = current.fontWeight == "bold" ? "regular" : "bold"
        }
    }

    private func setTextAlignment(_ alignment: String) {
        guard let element = selectedElement, element.kind == .text else { return }
        updateElementProperty(element) { $0.textAlignment = alignment }
    }

    private func bringSelectedElementToFront() {
        guard let selectedElementID, selectedSlideIndex < deck.slides.count,
              let idx = deck.slides[selectedSlideIndex].elements.firstIndex(where: { $0.id == selectedElementID }) else { return }
        let element = deck.slides[selectedSlideIndex].elements.remove(at: idx)
        deck.slides[selectedSlideIndex].elements.append(element)
        saveDeck()
    }

    private func sendSelectedElementToBack() {
        guard let selectedElementID, selectedSlideIndex < deck.slides.count,
              let idx = deck.slides[selectedSlideIndex].elements.firstIndex(where: { $0.id == selectedElementID }) else { return }
        let element = deck.slides[selectedSlideIndex].elements.remove(at: idx)
        deck.slides[selectedSlideIndex].elements.insert(element, at: 0)
        saveDeck()
    }

    private func centerSelectedElement() {
        guard let element = selectedElement else { return }
        updateElementProperty(element) { current in
            current.x = defaultCanvasCenter.x
            current.y = defaultCanvasCenter.y
        }
    }

    private func nudgeSelectedElement(dx: Double, dy: Double) {
        guard let element = selectedElement else { return }
        updateElementProperty(element) { current in
            current.x += dx
            current.y += dy
        }
    }

    private var supportsImagePlayground: Bool {
        if #available(iOS 18.1, *) { return true }
        return false
    }

    private var imagePlaygroundConcept: String {
        let title = selectedSlide?.title.trimmingCharacters(in: .whitespacesAndNewlines) ?? "presentation slide"
        return "Modern professional slide background for \(title)"
    }

    private func saveDeck() {
        manager.updateDeck(deck)
    }
}

private struct SlideCanvasElementView: View {
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
        case .text, .bullets:
            Text(element.text)
                .font(.system(size: element.fontSize, weight: element.fontWeight == "bold" ? .bold : .regular))
                .foregroundColor(Color(hex: element.textColor))
                .multilineTextAlignment(textAlignment)
                .frame(width: element.width, height: element.height)
        case .image:
            if let data = element.imageData, let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: element.width, height: element.height)
                    .clipped()
            } else if let imageURL = element.imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        ZStack {
                            Color.gray.opacity(0.3)
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    case .empty:
                        Color.gray.opacity(0.1)
                            .overlay { ProgressView() }
                    @unknown default:
                        Color.gray.opacity(0.3)
                    }
                }
                .frame(width: element.width, height: element.height)
                .clipped()
                .cornerRadius(8)
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
        case .chart:
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.16))
                VStack(spacing: 6) {
                    Image(systemName: "chart.bar.fill")
                        .foregroundStyle(.white)
                    Text(element.chartData?.title ?? "Chart")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: element.width, height: element.height)
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
        let fill = Color(hex: element.fillColor)
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

private struct ImagePlaygroundSlideModifier: ViewModifier {
    @Binding var isPresented: Bool
    let concept: String
    let onResult: (URL) -> Void

    func body(content: Content) -> some View {
        if #available(iOS 18.1, *) {
            content
                .imagePlaygroundSheet(
                    isPresented: $isPresented,
                    concept: concept
                ) { url in
                    onResult(url)
                }
        } else {
            content
        }
    }
}
