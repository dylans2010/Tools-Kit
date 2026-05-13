import SwiftUI
import Aurora

/// SiriCoreUIView provides a production-grade control surface for the Aurora animation engine.
/// It enables real-time adjustments to animation intensity, speed, and preset moods.
struct SiriCoreUIView: View {
    enum ViewState: String, CaseIterable, Identifiable, Hashable {
        case idle = "Idle"
        case active = "Active"
        case listening = "Listening"

        var id: String { rawValue }

        var style: AuroraGlow.Style {
            switch self {
            case .idle: return .subtle
            case .active: return .dramatic
            case .listening: return .standard
            }
        }

        var mood: AuroraGlow.Mood? {
            switch self {
            case .listening: return .listening
            default: return nil
            }
        }
    }

    @State private var state: ViewState = .idle
    @State private var intensity: Double = 0.5
    @State private var speed: Double = 0.12
    @State private var palette: AuroraGlow.Palette = .appleIntelligence
    @State private var reactiveMotion: Bool = true

    private enum PaletteOption: String, CaseIterable, Identifiable {
        case appleIntelligence = "Apple Intelligence"
        case sunset = "Sunset"
        case ocean = "Ocean"
        case forest = "Forest"
        case cyberpunk = "Cyberpunk"
        case monochrome = "Monochrome"

        var id: String { rawValue }

        var palette: AuroraGlow.Palette {
            switch self {
            case .appleIntelligence: return .appleIntelligence
            case .sunset: return .sunset
            case .ocean: return .ocean
            case .forest: return .forest
            case .cyberpunk: return .cyberpunk
            case .monochrome: return .monochrome
            }
        }

        init(palette: AuroraGlow.Palette) {
            switch palette {
            case .appleIntelligence: self = .appleIntelligence
            case .sunset: self = .sunset
            case .ocean: self = .ocean
            case .forest: self = .forest
            case .cyberpunk: self = .cyberpunk
            case .monochrome: self = .monochrome
            // AuroraGlow.Palette is defined in an external module and may grow with new
            // public cases. Fall back to the default palette for unsupported values.
            default: self = .appleIntelligence
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Preview Area
            ZStack {
                Color.black.ignoresSafeArea()

                contentPreview
                    .glow(
                        baseGlow
                            .speed(speed)
                            .glowSize(intensity * 40 + 10)
                            .palette(palette)
                            .washPeak(reactiveMotion ? 0.15 : 0.0)
                    )
            }
            .frame(height: 300)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding()

            // Control Surface
            List {
                Section {
                    Picker("Current State", selection: $state) {
                        ForEach(ViewState.allCases) { state in
                            Text(state.rawValue).tag(state)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker(
                        "Palette",
                        selection: Binding<PaletteOption>(
                            get: { PaletteOption(palette: palette) },
                            set: { palette = $0.palette }
                        )
                    ) {
                        ForEach(PaletteOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                } header: {
                    Text("State & Style")
                }

                Section {
                    VStack(alignment: .leading) {
                        Text("Intensity: \(intensity, specifier: "%.2f")")
                        Slider(value: $intensity, in: 0...1)
                    }

                    VStack(alignment: .leading) {
                        Text("Speed: \(speed, specifier: "%.2f")")
                        Slider(value: $speed, in: 0.01...0.5)
                    }

                    Toggle("Reactive Motion (Wash Effect)", isOn: $reactiveMotion)
                } header: {
                    Text("Parameters")
                }

                Section {
                    Button("Reset Defaults") {
                        intensity = 0.5
                        speed = 0.12
                        state = .idle
                        palette = .appleIntelligence
                        reactiveMotion = true
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Siri Core UI")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var baseGlow: AuroraGlow {
        if let mood = state.mood {
            return AuroraGlow(state.style).mood(mood)
        } else {
            return AuroraGlow(state.style)
        }
    }

    private var contentPreview: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundStyle(.white)

            Text(state.rawValue)
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(40)
        .background(.ultraThinMaterial, in: Circle())
    }
}

#Preview {
    NavigationStack {
        SiriCoreUIView()
    }
}
