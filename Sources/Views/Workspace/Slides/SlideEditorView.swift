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
    @State private var showingAddShape = false
    @State private var showingThemePicker = false
    @State private var showingLayoutPicker = false

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
        HStack(spacing: 0) {
            // Slide list sidebar
            slideListSidebar
                .frame(width: 100)
                .background(Color(.secondarySystemBackground))

            Divider()

            // Canvas + Properties
            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    canvasToolbar
                    Divider()
                    if let slide = selectedSlide {
                        canvasArea(slide: slide)
                    } else {
                        Spacer()
                    }
                }

                // Properties Panel when element selected
                if let element = selectedElement {
                    Divider()
                    propertiesPanel(element: element)
                        .frame(width: 220)
                        .background(Color(.secondarySystemBackground))
                }
            }
        }
        .navigationTitle(deck.title)
        .navigationBarTitleDisplayMode(.inline)
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
        .sheet(isPresented: $showingColorPicker) {
            backgroundColorPicker
        }
        .sheet(isPresented: $showingThemePicker) {
            themePicker
        }
        .sheet(isPresented: $showingLayoutPicker) {
            layoutPicker
        }
    }

    // MARK: - Properties Panel

    private func propertiesPanel(element: SlideElement) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Properties")
                    .font(.headline)
                    .padding(.top, 12)

                // Position & Size
                propertyGroup("Position & Size") {
                    propertyRow("X") {
                        Stepper("\(Int(element.x))", value: bindingFor(\.x, element: element), in: 0...2000, step: 10)
                    }
                    propertyRow("Y") {
                        Stepper("\(Int(element.y))", value: bindingFor(\.y, element: element), in: 0...2000, step: 10)
                    }
                    propertyRow("W") {
                        Stepper("\(Int(element.width))", value: bindingFor(\.width, element: element), in: 20...1200, step: 10)
                    }
                    propertyRow("H") {
                        Stepper("\(Int(element.height))", value: bindingFor(\.height, element: element), in: 20...800, step: 10)
                    }
                }

                // Text-specific properties
                if element.kind == .text {
                    propertyGroup("Text") {
                        propertyRow("Size") {
                            Stepper("\(Int(element.fontSize))pt", value: bindingFor(\.fontSize, element: element), in: 8...120, step: 2)
                        }
                        HStack(spacing: 6) {
                            Text("Bold")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Toggle("", isOn: bindingBool(element: element, keyPath: \.fontWeight, trueValue: "bold", falseValue: "regular"))
                                .labelsHidden()
                        }
                        .padding(.horizontal, 8)
                        HStack(spacing: 6) {
                            Text("Align")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            HStack(spacing: 4) {
                                alignButton("L", value: "leading", element: element)
                                alignButton("C", value: "center", element: element)
                                alignButton("R", value: "trailing", element: element)
                            }
                        }
                        .padding(.horizontal, 8)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Text Color")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            colorSwatches(for: element, isText: true)
                        }
                        .padding(.horizontal, 8)
                    }
                }

                // Shape-specific properties
                if element.kind == .shape {
                    propertyGroup("Shape") {
                        propertyRow("Radius") {
                            Stepper("\(Int(element.cornerRadius))px", value: bindingFor(\.cornerRadius, element: element), in: 0...100, step: 4)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Fill Color")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            colorSwatches(for: element, isText: false)
                        }
                        .padding(.horizontal, 8)
                    }
                }

                // Order
                propertyGroup("Order") {
                    HStack(spacing: 8) {
                        orderButton("↑ Forward") { bringForward(element) }
                        orderButton("↓ Back") { sendBack(element) }
                    }
                    .padding(.horizontal, 8)
                }

                // Actions
                propertyGroup("Actions") {
                    Button {
                        duplicateElement(element)
                    } label: {
                        Label("Duplicate", systemImage: "doc.on.doc")
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 8)

                    Button(role: .destructive) {
                        deleteSelectedElement()
                    } label: {
                        Label("Delete", systemImage: "trash")
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 8)
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 20)
        }
    }

    @ViewBuilder
    private func propertyGroup<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.bold())
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
            content()
        }
    }

    @ViewBuilder
    private func propertyRow<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 24, alignment: .leading)
            Spacer()
            content()
                .font(.caption)
        }
        .padding(.horizontal, 8)
    }

    private func alignButton(_ label: String, value: String, element: SlideElement) -> some View {
        Button(label) {
            updateElementProperty(element) { el in
                el.textAlignment = value
            }
        }
        .font(.caption.bold())
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(element.textAlignment == value ? Color.blue : Color(.systemGray5))
        .foregroundColor(element.textAlignment == value ? .white : .primary)
        .cornerRadius(6)
        .buttonStyle(.plain)
    }

    private func orderButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(Color(.systemGray5))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    private func colorSwatches(for element: SlideElement, isText: Bool) -> some View {
        let colors = ["FFFFFF", "000000", "FF3B30", "FF9500", "FFCC00",
                      "34C759", "007AFF", "5856D6", "AF52DE", "636366"]
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 6) {
            ForEach(colors, id: \.self) { hex in
                Button {
                    updateElementProperty(element) { el in
                        if isText { el.textColor = hex } else { el.fillColor = hex }
                    }
                } label: {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: hex) ?? .blue)
                        .frame(height: 22)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.primary.opacity(0.2), lineWidth: 0.5)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Property Bindings

    private func bindingFor(_ keyPath: WritableKeyPath<SlideElement, Double>, element: SlideElement) -> Binding<Double> {
        Binding(
            get: {
                selectedElement?[keyPath: keyPath] ?? element[keyPath: keyPath]
            },
            set: { newValue in
                updateElementProperty(element) { el in
                    el[keyPath: keyPath] = newValue
                }
            }
        )
    }

    private func bindingBool(element: SlideElement, keyPath: WritableKeyPath<SlideElement, String>, trueValue: String, falseValue: String) -> Binding<Bool> {
        Binding(
            get: { selectedElement?[keyPath: keyPath] == trueValue },
            set: { on in
                updateElementProperty(element) { el in
                    el[keyPath: keyPath] = on ? trueValue : falseValue
                }
            }
        )
    }

    private func updateElementProperty(_ element: SlideElement, update: (inout SlideElement) -> Void) {
        guard selectedSlideIndex < deck.slides.count,
              let idx = deck.slides[selectedSlideIndex].elements.firstIndex(where: { $0.id == element.id }) else { return }
        update(&deck.slides[selectedSlideIndex].elements[idx])
        saveDeck()
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
                showingLayoutPicker = true
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
                toolbarButton("Add", icon: "plus.square") {
                    showingAddElement = true
                }

                if selectedElementID != nil {
                    toolbarButton("Duplicate", icon: "doc.on.doc", tint: .indigo) {
                        if let el = selectedElement { duplicateElement(el) }
                    }
                    toolbarButton("Delete", icon: "trash", tint: .red) {
                        deleteSelectedElement()
                    }
                }

                toolbarButton("Background", icon: "paintpalette") {
                    showingColorPicker = true
                }

                toolbarButton("Theme", icon: "wand.and.stars", tint: .purple) {
                    showingThemePicker = true
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
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

    // MARK: - Theme Picker

    private var themePicker: some View {
        NavigationStack {
            let themes: [(String, String, String)] = [
                ("Ocean", "1E3A5F", "FFFFFF"),
                ("Forest", "1B3A2A", "FFFFFF"),
                ("Sunset", "7B2D1E", "FFCC00"),
                ("Minimal", "F5F5F7", "000000"),
                ("Purple Night", "2D1B69", "FFFFFF"),
                ("Charcoal", "2C2C2E", "FFFFFF")
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
                                .overlay(
                                    Text("Aa")
                                        .font(.caption.bold())
                                        .foregroundColor(Color(hex: text) ?? .white)
                                )
                            Text(name)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Apply Theme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { showingThemePicker = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Layout Picker (Add Slide)

    private var layoutPicker: some View {
        NavigationStack {
            let layouts: [(String, String)] = [
                ("Blank", "square"),
                ("Title", "text.badge.plus"),
                ("Content", "doc.text"),
                ("Two-Column", "rectangle.split.2x1"),
                ("Quote", "quote.bubble"),
                ("Image + Text", "photo.badge.plus")
            ]
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(layouts, id: \.0) { name, icon in
                    Button {
                        addSlideWithLayout(name)
                        showingLayoutPicker = false
                    } label: {
                        VStack(spacing: 10) {
                            Image(systemName: icon)
                                .font(.largeTitle)
                                .foregroundColor(.blue)
                            Text(name)
                                .font(.caption.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(14)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .navigationTitle("Add Slide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { showingLayoutPicker = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Actions

    private func addSlide() {
        let slide = Slide.blank(title: "Slide \(deck.slides.count + 1)")
        deck.slides.append(slide)
        selectedSlideIndex = deck.slides.count - 1
        selectedElementID = nil
        saveDeck()
    }

    private func addSlideWithLayout(_ layout: String) {
        var slide = Slide.blank(title: "Slide \(deck.slides.count + 1)")
        switch layout {
        case "Title":
            var titleEl = SlideElement(kind: .text)
            titleEl.text = "Title"; titleEl.fontSize = 48
            titleEl.x = 200; titleEl.y = 150; titleEl.width = 560; titleEl.height = 80
            titleEl.textColor = "FFFFFF"
            var subtitleEl = SlideElement(kind: .text)
            subtitleEl.text = "Subtitle"; subtitleEl.fontSize = 28
            subtitleEl.x = 200; subtitleEl.y = 260; subtitleEl.width = 560; subtitleEl.height = 50
            subtitleEl.textColor = "CCCCCC"
            slide.elements = [titleEl, subtitleEl]
        case "Content":
            var titleEl = SlideElement(kind: .text)
            titleEl.text = "Title"; titleEl.fontSize = 36
            titleEl.x = 50; titleEl.y = 60; titleEl.width = 860; titleEl.height = 60
            titleEl.textColor = "FFFFFF"
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

    private func bringForward(_ element: SlideElement) {
        guard selectedSlideIndex < deck.slides.count,
              let idx = deck.slides[selectedSlideIndex].elements.firstIndex(where: { $0.id == element.id }),
              idx < deck.slides[selectedSlideIndex].elements.count - 1 else { return }
        deck.slides[selectedSlideIndex].elements.swapAt(idx, idx + 1)
        saveDeck()
    }

    private func sendBack(_ element: SlideElement) {
        guard selectedSlideIndex < deck.slides.count,
              let idx = deck.slides[selectedSlideIndex].elements.firstIndex(where: { $0.id == element.id }),
              idx > 0 else { return }
        deck.slides[selectedSlideIndex].elements.swapAt(idx, idx - 1)
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

// MARK: - Element Edit Sheet

private struct ElementEditSheet: View {
    @State var element: SlideElement
    let onSave: (SlideElement) -> Void
    @Environment(\.dismiss) private var dismiss

    private let textColors = ["FFFFFF", "000000", "FF3B30", "FF9500", "FFCC00",
                               "34C759", "007AFF", "5856D6", "AF52DE", "636366"]
    private let fillColors = ["3B82F6", "EF4444", "10B981", "F59E0B", "8B5CF6",
                               "EC4899", "06B6D4", "84CC16", "F97316", "6B7280"]

    var body: some View {
        NavigationStack {
            Form {
                if element.kind == .text {
                    Section("Text Content") {
                        TextField("Content", text: $element.text, axis: .vertical)
                            .lineLimit(4)
                    }
                    Section("Text Styling") {
                        Stepper("Font size: \(Int(element.fontSize))pt", value: $element.fontSize, in: 8...120, step: 2)
                        Picker("Weight", selection: $element.fontWeight) {
                            Text("Regular").tag("regular")
                            Text("Bold").tag("bold")
                        }
                        Picker("Alignment", selection: $element.textAlignment) {
                            Text("Left").tag("leading")
                            Text("Center").tag("center")
                            Text("Right").tag("trailing")
                        }
                        .pickerStyle(.segmented)
                    }
                    Section("Text Color") {
                        colorGrid(colors: textColors, current: element.textColor) { hex in
                            element.textColor = hex
                        }
                    }
                }

                if element.kind == .shape {
                    Section("Shape") {
                        Picker("Kind", selection: $element.shapeKind) {
                            ForEach(SlideElement.ShapeKind.allCases, id: \.self) {
                                Text($0.displayName).tag($0)
                            }
                        }
                        Stepper("Corner Radius: \(Int(element.cornerRadius))px", value: $element.cornerRadius, in: 0...60, step: 4)
                    }
                    Section("Fill Color") {
                        colorGrid(colors: fillColors, current: element.fillColor) { hex in
                            element.fillColor = hex
                        }
                    }
                }

                Section("Size & Position") {
                    Stepper("Width: \(Int(element.width))px", value: $element.width, in: 20...1200, step: 10)
                    Stepper("Height: \(Int(element.height))px", value: $element.height, in: 20...800, step: 10)
                    Stepper("X: \(Int(element.x))px", value: $element.x, in: 0...2000, step: 10)
                    Stepper("Y: \(Int(element.y))px", value: $element.y, in: 0...2000, step: 10)
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

    private func colorGrid(colors: [String], current: String, onSelect: @escaping (String) -> Void) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
            ForEach(colors, id: \.self) { hex in
                Button {
                    onSelect(hex)
                } label: {
                    Circle()
                        .fill(Color(hex: hex) ?? .blue)
                        .frame(height: 32)
                        .overlay(
                            Circle()
                                .stroke(current == hex ? Color.primary : Color.clear, lineWidth: 2.5)
                                .padding(2)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Safe subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
