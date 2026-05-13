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

    enum PaletteOption: String, CaseIterable, Identifiable, Sendable {
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
        ZStack {
            // Full-screen Aurora Glow background
            AuroraGlow(state.style)
                .mood(state.mood ?? .listening) // Use mood if available, default to listening for demo
                .palette(palette)
                .speed(speed)
                .glowSize(intensity * 40 + 10)
                .washPeak(reactiveMotion ? 0.15 : 0.0)
                .ignoresSafeArea()

            // Foreground UI Content
            ScrollView {
                VStack(spacing: 32) {
                    contentPreview
                        .frame(height: 300)
                        .padding(.top, 40)

                    controlsSection
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.1), radius: 10)
                        )
                        .padding(.horizontal)
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Siri Core UI")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var contentPreview: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )

                Image(systemName: state == .listening ? "mic.fill" : "sparkles")
                    .font(.system(size: 48))
                    .foregroundStyle(.white)
                    .symbolEffect(.bounce, value: state)
            }

            Text(state.rawValue)
                .font(.title2.bold())
                .foregroundColor(.white)
                .shadow(radius: 5)
        }
    }

    private var controlsSection: some View {
        VStack(spacing: 24) {
            stateSelectorSection
            paletteSelectionSection
            slidersSection
            resetDefaultsButton
        }
        .padding()
    }

    private var stateSelectorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Current State", systemImage: "waveform")
                .font(.headline)

            Picker("Current State", selection: $state) {
                ForEach(ViewState.allCases) { state in
                    Text(state.rawValue).tag(state)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var paletteSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Palette", systemImage: "paintpalette")
                .font(.headline)

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
            }
        }
    }

    private var slidersSection: some View {
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
            .background(Color(.secondarySystemGroupedBackground).opacity(0.5))
            .cornerRadius(16)
        }
    }

    private var resetDefaultsButton: some View {
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
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemGroupedBackground).opacity(0.8))
                .cornerRadius(16)
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
                .background(isSelected ? Color.blue : Color(.secondarySystemGroupedBackground).opacity(0.5))
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
        .background(Color(.secondarySystemGroupedBackground).opacity(0.5))
        .cornerRadius(16)
    }
}

#Preview {
    NavigationStack {
        SiriCoreUIView()
    }
}
