import SwiftUI

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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    artworkPreview
                    gradientSection
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

    private var gradientBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: stops.map(\.color)),
            startPoint: gradientStart,
            endPoint: gradientEnd
        )
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
                // Color stops
                ForEach(Array(stops.enumerated()), id: \.element.id) { idx, stop in
                    HStack {
                        ColorPicker("Color \(idx + 1)", selection: Binding(
                            get: { stops[idx].color },
                            set: { stops[idx].color = $0; generatedImage = nil }
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

                if stops.count < 5 {
                    Button {
                        stops.append(GradientStop(color: .pink))
                        generatedImage = nil
                    } label: {
                        Label("Add Color Stop", systemImage: "plus.circle")
                    }
                    .font(.subheadline)
                }

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Angle")
                        Spacer()
                        Text("\(Int(gradientAngle))°")
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $gradientAngle, in: 0...360, step: 5)
                        .onChange(of: gradientAngle) { _ in generatedImage = nil }
                }

                // Quick palette
                HStack(spacing: 10) {
                    ForEach(quickPalettes, id: \.0) { name, colors in
                        Button {
                            stops = colors.map { GradientStop(color: $0) }
                            generatedImage = nil
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
            ("Sunset", [.orange, .red, .purple]),
            ("Ocean",  [.cyan,   .blue]),
            ("Forest", [.green,  .teal]),
            ("Berry",  [.pink,   .purple, .indigo]),
            ("Gold",   [.yellow, .orange])
        ]
    }

    private func quickPaletteChip(colors: [Color], name: String) -> some View {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            .frame(width: 44, height: 44)
            .cornerRadius(10)
            .overlay(
                Text(name)
                    .font(.system(size: 7, weight: .semibold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.4), radius: 2)
                    .padding(2),
                alignment: .bottom
            )
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
                    openImagePlayground()
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

    private func openImagePlayground() {
        // Image Playground is available on iOS 18.1+ with Apple Intelligence
        // The ImagePlayground framework sheet is presented via SwiftUI
        showImagePlayground = true
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
