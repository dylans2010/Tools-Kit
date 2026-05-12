import SwiftUI
import Aurora

/// SiriCoreUIView provides a production-grade control surface for the Aurora animation engine.
/// It enables real-time adjustments to animation intensity, speed, and preset moods.
struct SiriCoreUIView: View {
    enum ViewState: String, CaseIterable, Identifiable {
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
                Section("State & Style") {
                    Picker("Current State", selection: $state) {
                        ForEach(ViewState.allCases, id: \.self) { state in
                            Text(state.rawValue).tag(state)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Palette", selection: $palette) {
                        Text("Apple Intelligence").tag(AuroraGlow.Palette.appleIntelligence)
                        Text("Sunset").tag(AuroraGlow.Palette.sunset)
                        Text("Ocean").tag(AuroraGlow.Palette.ocean)
                        Text("Forest").tag(AuroraGlow.Palette.forest)
                        Text("Cyberpunk").tag(AuroraGlow.Palette.cyberpunk)
                        Text("Monochrome").tag(AuroraGlow.Palette.monochrome)
                    }
                }

                Section("Parameters") {
                    VStack(alignment: .leading) {
                        Text("Intensity: \(intensity, specifier: "%.2f")")
                        Slider(value: $intensity, in: 0...1)
                    }

                    VStack(alignment: .leading) {
                        Text("Speed: \(speed, specifier: "%.2f")")
                        Slider(value: $speed, in: 0.01...0.5)
                    }

                    Toggle("Reactive Motion (Wash Effect)", isOn: $reactiveMotion)
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
