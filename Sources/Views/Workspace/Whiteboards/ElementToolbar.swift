import SwiftUI

struct ElementToolbar: View {
    @Binding var element: CanvasElement
    let onDelete: () -> Void
    let onDuplicate: () -> Void
    let onBringToFront: () -> Void
    let onSendToBack: () -> Void

    @State private var activeSection: ToolbarSection = .properties

    enum ToolbarSection: String, CaseIterable, Sendable {
        case properties = "Properties"
        case style = "Style"
        case arrange = "Arrange"
    }

    private let presetColors: [String] = [
        "FFFFFF", "000000", "EF4444", "F97316", "F59E0B",
        "22C55E", "3B82F6", "8B5CF6", "EC4899", "6B7280"
    ]

    var body: some View {
        VStack(spacing: 0) {
            handle

            sectionPicker

            Divider().opacity(0.3)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    switch activeSection {
                    case .properties:
                        propertiesForKind(element.kind)
                    case .style:
                        styleControls
                    case .arrange:
                        arrangeControls
                    }
                }
                .padding(16)
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var handle: some View {
        Capsule()
            .fill(Color.gray.opacity(0.4))
            .frame(width: 36, height: 5)
            .padding(.top, 8)
            .padding(.bottom, 4)
    }

    private var sectionPicker: some View {
        HStack(spacing: 0) {
            ForEach(ToolbarSection.allCases, id: \.self) { section in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { activeSection = section }
                } label: {
                    Text(section.rawValue)
                        .font(.system(size: 13, weight: activeSection == section ? .bold : .medium))
                        .foregroundStyle(activeSection == section ? .white : .secondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(activeSection == section ? Color.accentColor.opacity(0.5) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
    }

    // MARK: - Properties per Element Kind

    @ViewBuilder
    private func propertiesForKind(_ kind: CanvasElement.ElementKind) -> some View {
        switch kind {
        case .text:
            textProperties
        case .stickyNote:
            stickyNoteProperties
        case .rectangle:
            rectangleProperties
        case .circle:
            circleProperties
        case .arrow:
            arrowProperties
        case .connector:
            connectorProperties
        case .image, .mediaPlaceholder:
            mediaProperties
        case .drawing:
            drawingProperties
        }
    }

    // MARK: - Text Properties

    private var textProperties: some View {
        VStack(alignment: .leading, spacing: 12) {
            toolbarLabel("Text", icon: "textformat")

            TextField("Content", text: $element.content, axis: .vertical)
                .lineLimit(1...6)
                .textFieldStyle(.roundedBorder)

            fontSizeSlider
            fillColorPicker(label: "Text Color")
        }
    }

    // MARK: - Sticky Note Properties

    private var stickyNoteProperties: some View {
        VStack(alignment: .leading, spacing: 12) {
            toolbarLabel("Sticky Note", icon: "note.text")

            TextField("Note content", text: $element.content, axis: .vertical)
                .lineLimit(1...8)
                .textFieldStyle(.roundedBorder)

            fontSizeSlider
            fillColorPicker(label: "Background")
            strokeColorPicker
            cornerRadiusInfo
        }
    }

    // MARK: - Rectangle Properties

    private var rectangleProperties: some View {
        VStack(alignment: .leading, spacing: 12) {
            toolbarLabel("Rectangle", icon: "rectangle")

            fillColorPicker(label: "Fill Color")
            strokeColorPicker
            strokeWidthSlider
            sizeControls
        }
    }

    // MARK: - Circle Properties

    private var circleProperties: some View {
        VStack(alignment: .leading, spacing: 12) {
            toolbarLabel("Circle", icon: "circle")

            fillColorPicker(label: "Fill Color")
            strokeColorPicker
            strokeWidthSlider
            sizeControls
        }
    }

    // MARK: - Arrow Properties

    private var arrowProperties: some View {
        VStack(alignment: .leading, spacing: 12) {
            toolbarLabel("Arrow", icon: "arrow.right")

            fillColorPicker(label: "Arrow Color")
            strokeWidthSlider

            HStack {
                Text("Length")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("\(Int(element.width))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: $element.width, in: 60...500, step: 10)
                .tint(.accentColor)
        }
    }

    // MARK: - Connector Properties

    private var connectorProperties: some View {
        VStack(alignment: .leading, spacing: 12) {
            toolbarLabel("Connector", icon: "link")

            fillColorPicker(label: "Line Color")
            strokeColorPicker
            strokeWidthSlider
        }
    }

    // MARK: - Media Properties

    private var mediaProperties: some View {
        VStack(alignment: .leading, spacing: 12) {
            toolbarLabel("Media", icon: "photo")

            if !element.content.isEmpty {
                Text("Source URL")
                    .font(.subheadline.weight(.medium))
                Text(element.content)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            sizeControls
            fillColorPicker(label: "Border Color")
        }
    }

    // MARK: - Drawing Properties

    private var drawingProperties: some View {
        VStack(alignment: .leading, spacing: 12) {
            toolbarLabel("Drawing", icon: "scribble")

            fillColorPicker(label: "Stroke Color")
            strokeWidthSlider
        }
    }

    // MARK: - Style Controls

    private var styleControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            toolbarLabel("Appearance", icon: "paintbrush")

            fillColorPicker(label: "Fill")
            strokeColorPicker
            strokeWidthSlider

            rotationSlider

            HStack {
                Text("Locked")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Toggle("", isOn: $element.isLocked)
                    .labelsHidden()
            }
        }
    }

    // MARK: - Arrange Controls

    private var arrangeControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            toolbarLabel("Arrange", icon: "square.3.layers.3d")

            sizeControls
            positionControls

            HStack(spacing: 12) {
                arrangeButton(title: "Front", icon: "square.3.layers.3d.top.filled") {
                    onBringToFront()
                }
                arrangeButton(title: "Back", icon: "square.3.layers.3d.bottom.filled") {
                    onSendToBack()
                }
            }

            HStack(spacing: 12) {
                arrangeButton(title: "Duplicate", icon: "plus.square.on.square") {
                    onDuplicate()
                }
                arrangeButton(title: "Delete", icon: "trash", tint: .red) {
                    onDelete()
                }
            }
        }
    }

    // MARK: - Shared Components

    private func toolbarLabel(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.accentColor)
            Text(title)
                .font(.headline)
        }
    }

    private func fillColorPicker(label: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.subheadline.weight(.medium))
                Spacer()
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: element.colorHex) ?? .gray)
                    .frame(width: 22, height: 22)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(.white.opacity(0.3), lineWidth: 1)
                    )
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 10), spacing: 4) {
                ForEach(presetColors, id: \.self) { hex in
                    Button {
                        withAnimation(.easeInOut(duration: 0.1)) { element.colorHex = hex }
                    } label: {
                        Circle()
                            .fill(Color(hex: hex) ?? .gray)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(element.colorHex == hex ? Color.white : Color.white.opacity(0.1), lineWidth: element.colorHex == hex ? 2.5 : 0.5)
                            )
                            .scaleEffect(element.colorHex == hex ? 1.15 : 1.0)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var strokeColorPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Stroke")
                    .font(.subheadline.weight(.medium))
                Spacer()
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: element.strokeColorHex) ?? .gray)
                    .frame(width: 22, height: 22)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(.white.opacity(0.3), lineWidth: 1)
                    )
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 10), spacing: 4) {
                ForEach(presetColors, id: \.self) { hex in
                    Button {
                        withAnimation(.easeInOut(duration: 0.1)) { element.strokeColorHex = hex }
                    } label: {
                        Circle()
                            .fill(Color(hex: hex) ?? .gray)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(element.strokeColorHex == hex ? Color.white : Color.white.opacity(0.1), lineWidth: element.strokeColorHex == hex ? 2.5 : 0.5)
                            )
                            .scaleEffect(element.strokeColorHex == hex ? 1.15 : 1.0)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var strokeWidthSlider: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Stroke Width")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(String(format: "%.1f", element.strokeWidth))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: $element.strokeWidth, in: 0.5...12, step: 0.5)
                .tint(.accentColor)
        }
    }

    private var fontSizeSlider: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Font Size")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("\(Int(element.fontSize))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: $element.fontSize, in: 8...72, step: 1)
                .tint(.accentColor)
        }
    }

    private var rotationSlider: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Rotation")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("\(Int(element.rotation))\u{00B0}")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: $element.rotation, in: 0...360, step: 1)
                .tint(.accentColor)
        }
    }

    private var sizeControls: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Size")
                .font(.subheadline.weight(.medium))

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("W")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        TextField("", value: $element.width, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 70)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("H")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        TextField("", value: $element.height, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 70)
                    }
                }
            }
        }
    }

    private var positionControls: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Position")
                .font(.subheadline.weight(.medium))

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("X")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    TextField("", value: $element.positionX, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 70)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Y")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    TextField("", value: $element.positionY, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 70)
                }
            }
        }
    }

    private var cornerRadiusInfo: some View {
        HStack {
            Text("Corner Radius")
                .font(.subheadline.weight(.medium))
            Spacer()
            Text("4 pt")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func arrangeButton(title: String, icon: String, tint: Color = .accentColor, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(tint.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(tint.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
