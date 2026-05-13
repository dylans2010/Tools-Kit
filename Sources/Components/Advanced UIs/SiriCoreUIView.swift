import SwiftUI
import Aurora

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

    var body: some View {
        ZStack {
            // Full-screen Aurora Glow background
            AuroraGlow(state.style)
                .mood(state.mood ?? .listening)
                .ignoresSafeArea()

            // Foreground UI Content
            VStack {
                Spacer()

                contentPreview
                    .frame(maxHeight: .infinity)

                Spacer()

                VStack(spacing: 24) {
                    stateSelectorSection
                    demosButton
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.2), radius: 20)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("Siri Core UI")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var contentPreview: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 140, height: 140)
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )

                Image(systemName: state == .listening ? "mic.fill" : "sparkles")
                    .font(.system(size: 56))
                    .foregroundStyle(.white)
                    .symbolEffect(.bounce, value: state)
            }

            Text(state.rawValue)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(radius: 10)
        }
    }

    private var stateSelectorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Animation State", systemImage: "waveform")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)

            Picker("Current State", selection: $state) {
                ForEach(ViewState.allCases) { state in
                    Text(state.rawValue).tag(state)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var demosButton: some View {
        NavigationLink(destination: DemoCatalogView()) {
            Label("See Demos", systemImage: "square.grid.2x2.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(16)
        }
    }
}


#Preview {
    NavigationStack {
        SiriCoreUIView()
    }
}
