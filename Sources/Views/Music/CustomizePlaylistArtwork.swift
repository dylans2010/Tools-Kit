import SwiftUI
import PhotosUI
#if canImport(ImagePlayground)
import ImagePlayground
#endif

// MARK: - Gradient Type

private enum GradientType: String, CaseIterable, Identifiable {
    case linear = "Linear"
    case radial  = "Radial"
    case angular = "Angular"
    var id: String { rawValue }
}

// MARK: - Gradient Color Stop

private struct GradientStop: Identifiable {
    var id = UUID()
    var color: Color
}

// MARK: - Sticker Model

private struct ArtworkSticker: Identifiable {
    var id = UUID()
    var emoji: String
    var position: CGPoint
    var scale: CGFloat = 1.0
}

// MARK: - CustomizePlaylistArtwork

struct CustomizePlaylistArtwork: View {
    @Binding var playlist: Playlist

    @Environment(\.dismiss) private var dismiss
    @StateObject private var library = MusicLibraryManager.shared

    // Gradient
    @State private var stops: [GradientStop] = [
        GradientStop(color: .purple),
        GradientStop(color: .blue)
    ]
    @State private var gradientAngle: Double = 135
    @State private var gradientType: GradientType = .linear

    // Uploaded image background
    @State private var uploadedBackground: UIImage?
    @State private var photoPickerItem: PhotosPickerItem?

    // Text overlay
    @State private var overlayText: String = ""
    @State private var textColor: Color = .white
    @State private var textSize: CGFloat = 28
    @State private var textBold: Bool = true

    // Stickers
    @State private var stickers: [ArtworkSticker] = []
    @State private var showStickerPicker = false

    // Image Playground (Apple Intelligence)
    @State private var showImagePlayground = false
    @State private var playgroundPrompt: String = ""
    @State private var generatedImage: UIImage?

    // Preview size
    private let artworkSize: CGFloat = 260
    private let radialGradientRadiusMultiplier: CGFloat = 0.7
    private let randomColorSaturation: Double = 0.8
    private let randomColorBrightness: Double = 0.9

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    artworkPreview
                    gradientSection
                    uploadSection
                    textSection
                    stickersSection
                    if supportsImagePlayground {
                        playgroundSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .navigationTitle("Customize Artwork")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveArtwork() }
                        .font(.headline)
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .sheet(isPresented: $showStickerPicker) {
                StickerPickerSheet { emoji in
                    stickers.append(ArtworkSticker(emoji: emoji, position: CGPoint(x: artworkSize / 2, y: artworkSize / 2)))
                    showStickerPicker = false
                }
            }
            .modifier(ImagePlaygroundModifier(
                isPresented: $showImagePlayground,
                concept: playgroundPrompt,
                onResult: { url in
                    if let data = try? Data(contentsOf: url),
                       let img = UIImage(data: data) {
                        generatedImage = img
                        uploadedBackground = nil
                    }
                }
            ))
        }
        .onChange(of: photoPickerItem) { newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    await MainActor.run {
                        uploadedBackground = img
                        generatedImage = nil
                    }
                }
            }
        }
    }

    // MARK: - Artwork Preview

    private var artworkPreview: some View {
        ZStack {
            artworkCanvas
                .frame(width: artworkSize, height: artworkSize)
                .cornerRadius(18)
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 8)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var artworkCanvas: some View {
        ZStack {
            if let img = generatedImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else if let img = uploadedBackground {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                gradientBackground
            }

            if !overlayText.isEmpty {
                Text(overlayText)
                    .font(.system(size: textSize, weight: textBold ? .bold : .regular))
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.center)
                    .padding(8)
                    .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
            }

            ForEach(stickers) { sticker in
                Text(sticker.emoji)
                    .font(.system(size: 36 * sticker.scale))
                    .position(sticker.position)
            }
        }
        .clipped()
    }

    @ViewBuilder
    private var gradientBackground: some View {
        let colors = stops.map(\.color)
        let gradient = Gradient(colors: colors)
        switch gradientType {
        case .linear:
            LinearGradient(gradient: gradient, startPoint: gradientStart, endPoint: gradientEnd)
        case .radial:
            RadialGradient(gradient: gradient, center: .center, startRadius: 0, endRadius: artworkSize * radialGradientRadiusMultiplier)
        case .angular:
            AngularGradient(gradient: gradient, center: .center, angle: .degrees(gradientAngle))
        }
    }

    private var gradientStart: UnitPoint {
        let rad = gradientAngle * .pi / 180
        return UnitPoint(x: 0.5 - 0.5 * cos(rad), y: 0.5 - 0.5 * sin(rad))
    }

    private var gradientEnd: UnitPoint {
        let rad = gradientAngle * .pi / 180
        return UnitPoint(x: 0.5 + 0.5 * cos(rad), y: 0.5 + 0.5 * sin(rad))
    }

    // MARK: - Gradient Section

    private var gradientSection: some View {
        cardSection("Gradient") {
            VStack(spacing: 14) {
                // Gradient type picker
                Picker("Type", selection: $gradientType) {
                    ForEach(GradientType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: gradientType) { _ in generatedImage = nil; uploadedBackground = nil }

                Divider()

                // Color stops (unlimited)
                ForEach(Array(stops.enumerated()), id: \.element.id) { idx, _ in
                    HStack {
                        ColorPicker("Color \(idx + 1)", selection: Binding(
                            get: { stops[idx].color },
                            set: { stops[idx].color = $0; generatedImage = nil; uploadedBackground = nil }
                        ))

                        if stops.count > 2 {
                            Button {
                                stops.remove(at: idx)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Button {
                    stops.append(GradientStop(color: randomBrightColor()))
                    generatedImage = nil
                    uploadedBackground = nil
                } label: {
                    Label("Add Color Stop", systemImage: "plus.circle")
                }
                .font(.subheadline)

                Divider()

                if gradientType != .radial {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Angle")
                            Spacer()
                            Text("\(Int(gradientAngle))°")
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: $gradientAngle, in: 0...360, step: 5)
                            .onChange(of: gradientAngle) { _ in generatedImage = nil; uploadedBackground = nil }
                    }

                    Divider()
                }

                // Quick palettes
                Text("Quick Palettes")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 52))], spacing: 10) {
                    ForEach(quickPalettes, id: \.0) { name, colors in
                        Button {
                            stops = colors.map { GradientStop(color: $0) }
                            generatedImage = nil
                            uploadedBackground = nil
                        } label: {
                            quickPaletteChip(colors: colors, name: name)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var quickPalettes: [(String, [Color])] {
        [
            ("Sunset",   [.orange, .red, .purple]),
            ("Ocean",    [.cyan, .blue]),
            ("Forest",   [.green, .teal]),
            ("Berry",    [.pink, .purple, .indigo]),
            ("Gold",     [.yellow, .orange]),
            ("Candy",    [.pink, .yellow, .cyan]),
            ("Aurora",   [.green, .cyan, .blue, .purple]),
            ("Neon",     [Color(red: 1, green: 0, blue: 0.5), Color(red: 0, green: 1, blue: 0.8)]),
            ("Dusk",     [Color(red: 0.1, green: 0.1, blue: 0.4), .purple, .orange]),
            ("Pastel",   [Color(red: 1, green: 0.8, blue: 0.9), Color(red: 0.8, green: 0.9, blue: 1)]),
            ("Fire",     [.yellow, .orange, .red, Color(red: 0.5, green: 0, blue: 0)]),
            ("Ice",      [.white, .cyan, .blue]),
            ("Lavender", [Color(red: 0.9, green: 0.8, blue: 1), .purple]),
            ("Mint",     [Color(red: 0.7, green: 1, blue: 0.85), .teal]),
            ("Rose",     [Color(red: 1, green: 0.85, blue: 0.85), .pink, .red]),
            ("Space",    [.black, Color(red: 0.1, green: 0, blue: 0.3), .indigo])
        ]
    }

    private func quickPaletteChip(colors: [Color], name: String) -> some View {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            .frame(width: 52, height: 52)
            .cornerRadius(10)
            .overlay(
                Text(name)
                    .font(.system(size: 7, weight: .semibold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2)
                    .padding(2),
                alignment: .bottom
            )
    }

    private func randomBrightColor() -> Color {
        let hue = Double.random(in: 0...1)
        return Color(hue: hue, saturation: randomColorSaturation, brightness: randomColorBrightness)
    }

    // MARK: - Upload Section

    private var uploadSection: some View {
        cardSection("Background Image") {
            VStack(spacing: 12) {
                if let img = uploadedBackground {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 80)
                        .clipped()
                        .cornerRadius(10)

                    Button(role: .destructive) {
                        uploadedBackground = nil
                        photoPickerItem = nil
                    } label: {
                        Label("Remove Image", systemImage: "trash")
                    }
                    .font(.subheadline)
                } else {
                    PhotosPicker(selection: $photoPickerItem, matching: .images) {
                        Label("Upload Image", systemImage: "photo.on.rectangle.angled")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    // MARK: - Text Section

    private var textSection: some View {
        cardSection("Text Overlay") {
            VStack(spacing: 12) {
                TextField("Playlist name or custom text", text: $overlayText)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    ColorPicker("Color", selection: $textColor)
                    Spacer()
                    Toggle("Bold", isOn: $textBold)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Size")
                        Spacer()
                        Text("\(Int(textSize))pt")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $textSize, in: 12...60)
                }
            }
        }
    }

    // MARK: - Stickers Section

    private var stickersSection: some View {
        cardSection("Stickers") {
            VStack(spacing: 12) {
                if stickers.isEmpty {
                    Text("No stickers added yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 10) {
                        ForEach(Array(stickers.enumerated()), id: \.element.id) { idx, sticker in
                            ZStack(alignment: .topTrailing) {
                                Text(sticker.emoji)
                                    .font(.system(size: 36))
                                    .frame(width: 50, height: 50)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(10)

                                Button {
                                    stickers.remove(at: idx)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                        .background(Color.white.clipShape(Circle()))
                                }
                                .offset(x: 6, y: -6)
                            }
                        }
                    }
                }

                Button {
                    showStickerPicker = true
                } label: {
                    Label("Add Sticker", systemImage: "face.smiling")
                }
                .font(.subheadline)
            }
        }
    }

    // MARK: - Image Playground Section

    private var supportsImagePlayground: Bool {
        if #available(iOS 18.1, *) {
            return true
        }
        return false
    }

    private var playgroundSection: some View {
        cardSection("Image Playground") {
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 22))
                        .foregroundStyle(.indigo.gradient)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Apple Intelligence")
                            .font(.subheadline.weight(.semibold))
                        Text("Generate artwork using AI")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }

                TextField("Describe your artwork…", text: $playgroundPrompt, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(2...4)

                Button {
                    showImagePlayground = true
                } label: {
                    Label("Generate with Image Playground", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
                .disabled(playgroundPrompt.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    // MARK: - Card Section

    private func cardSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)

            VStack(alignment: .leading, spacing: 0) {
                content()
                    .padding(16)
            }
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(14)
        }
    }

    // MARK: - Save

    private func saveArtwork() {
        let renderer = ImageRenderer(content:
            artworkCanvas
                .frame(width: artworkSize, height: artworkSize)
        )
        renderer.scale = 3
        if let uiImage = renderer.uiImage, let data = uiImage.jpegData(compressionQuality: 0.9) {
            var updated = playlist
            updated.customArtworkData = data
            library.updatePlaylist(updated)
        }
        dismiss()
    }
}

// MARK: - Image Playground View Modifier

/// Wraps `imagePlaygroundSheet` when available, no-op on older OS versions.
private struct ImagePlaygroundModifier: ViewModifier {
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

// MARK: - Sticker Picker Sheet

private struct StickerPickerSheet: View {
    let onSelect: (String) -> Void

    private let stickers: [[String]] = [
        ["🎵", "🎶", "🎸", "🎹", "🥁", "🎺", "🎷", "🎻"],
        ["🔥", "✨", "⭐️", "🌟", "💫", "🌙", "☀️", "🌈"],
        ["❤️", "💙", "💜", "🖤", "🤍", "💛", "🧡", "💚"],
        ["🦋", "🌸", "🌺", "🍀", "🌿", "🎋", "🌊", "🏔️"],
        ["😎", "🤩", "😈", "👑", "💎", "🎯", "🎮", "🕹️"],
        ["🚀", "🛸", "🌌", "⚡️", "🎆", "🎇", "🎉", "🥳"]
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(stickers, id: \.self) { row in
                        HStack(spacing: 12) {
                            ForEach(row, id: \.self) { emoji in
                                Button {
                                    onSelect(emoji)
                                } label: {
                                    Text(emoji)
                                        .font(.system(size: 36))
                                        .frame(width: 56, height: 56)
                                        .background(Color(.secondarySystemBackground))
                                        .cornerRadius(12)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Add Sticker")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }
}
