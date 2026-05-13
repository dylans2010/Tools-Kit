import SwiftUI
import Aurora

/// SiriCoreUIView provides a production-grade control surface for the Aurora animation engine.
/// It enables real-time adjustments to animation intensity, speed, and preset moods.
@MainActor
struct SiriCoreUIView: View {
    enum ViewState: String, CaseIterable, Identifiable, Hashable, Sendable {
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

    private enum PaletteOption: String, CaseIterable, Identifiable, Sendable {
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
            default: self = .appleIntelligence
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Modernized Preview Area
                ZStack {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(Color.black)
                        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)

                    contentPreview
                        .glow(
                            baseGlow
                                .speed(speed)
                                .glowSize(intensity * 40 + 10)
                                .palette(palette)
                                .washPeak(reactiveMotion ? 0.15 : 0.0)
                        )
                }
                .frame(height: 320)
                .padding(.horizontal)

                VStack(spacing: 20) {
                    // State Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Current State", systemImage: "waveform")
                            .font(.headline)
                            .padding(.horizontal)

                        Picker("Current State", selection: $state) {
                            ForEach(ViewState.allCases) { state in
                                Text(state.rawValue).tag(state)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                    }

                    // Palette Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Palette", systemImage: "paintpalette")
                            .font(.headline)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(PaletteOption.allCases) { option in
                                    PaletteChip(
                                        option: option,
                                        isSelected: PaletteOption(palette: palette) == option
                                    ) {
                                        palette = option.palette
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Sliders
                    VStack(spacing: 16) {
                        ParameterSlider(
                            label: "Intensity",
                            value: $intensity,
                            range: 0...1,
                            icon: "sparkles"
                        )

                        ParameterSlider(
                            label: "Speed",
                            value: $speed,
                            range: 0.01...0.5,
                            icon: "bolt.fill"
                        )

                        Toggle(isOn: $reactiveMotion) {
                            Label("Reactive Motion", systemImage: "move.3d")
                                .font(.headline)
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }

                    Button(role: .destructive) {
                        withAnimation {
                            intensity = 0.5
                            speed = 0.12
                            state = .idle
                            palette = .appleIntelligence
                            reactiveMotion = true
                        }
                    } label: {
                        Label("Reset Defaults", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(16)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
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
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 100, height: 100)

                Image(systemName: state == .listening ? "mic.fill" : "sparkles")
                    .font(.system(size: 44))
                    .foregroundStyle(.white)
                    .symbolEffect(.bounce, value: state)
            }

            Text(state.rawValue)
                .font(.title3.bold())
                .foregroundColor(.white)
        }
    }
}

struct PaletteChip: View {
    let option: SiriCoreUIView.PaletteOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(option.rawValue)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.secondarySystemGroupedBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.blue : Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

struct ParameterSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(label, systemImage: icon)
                    .font(.headline)
                Spacer()
                Text("\(value, specifier: "%.2f")")
                    .font(.subheadline.monospacedDigit())
                    .foregroundColor(.secondary)
            }

            Slider(value: $value, in: range)
                .tint(.blue)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

#Preview {
    NavigationStack {
        SiriCoreUIView()
    }
}
