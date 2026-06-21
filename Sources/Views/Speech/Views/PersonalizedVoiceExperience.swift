import SwiftUI
import AVFoundation

struct PersonalizedVoiceExperience: View {
    @StateObject private var ttsService = TTSService.shared
    
    // Local state for smooth slider interaction, synced with TTSService
    @State private var localPace: Float = 0.5
    @State private var localExpressiveness: Float = 1.0
    @State private var isPlayingPreview: Bool = false
    
    // Animation state
    @State private var orbScale: CGFloat = 1.0
    @State private var orbRotation: Double = 0.0
    
    // Haptics
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    
    // Debouncer for audio preview
    @State private var previewTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            // Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // Central Orb
                    orbView
                        .padding(.top, 40)
                    
                    Text(providerDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Controls
                    VStack(spacing: 24) {
                        sliderControl(
                            title: paceTitle,
                            value: $localPace,
                            range: paceRange,
                            icon: "tortoise.fill",
                            maxIcon: "hare.fill",
                            color: activeColor
                        )
                        
                        sliderControl(
                            title: expressivenessTitle,
                            value: $localExpressiveness,
                            range: expressivenessRange,
                            icon: "waveform.path",
                            maxIcon: "waveform.path.ecg",
                            color: activeColor
                        )
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Preview Button
                    Button(action: {
                        playPreview()
                    }) {
                        HStack {
                            Image(systemName: isPlayingPreview ? "stop.fill" : "play.fill")
                            Text(isPlayingPreview ? "Stop Preview" : "Preview Voice")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isPlayingPreview ? Color.red : activeColor)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
            }
        }
        .navigationTitle("Customize Voice")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            localPace = ttsService.pace
            localExpressiveness = ttsService.expressiveness
            lightImpact.prepare()
            mediumImpact.prepare()
        }
        .onChange(of: localPace) { newValue in
            ttsService.pace = newValue
            triggerPreviewDebounced()
        }
        .onChange(of: localExpressiveness) { newValue in
            ttsService.expressiveness = newValue
            triggerPreviewDebounced()
        }
    }
    
    // MARK: - Subviews
    
    private var orbView: some View {
        ZStack {
            Circle()
                .fill(activeColor.opacity(0.1))
                .frame(width: 200, height: 200)
                .scaleEffect(orbScale * 1.1)
            
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [activeColor.opacity(0.8), activeColor.opacity(0.4)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 150, height: 150)
                .scaleEffect(orbScale)
                .rotationEffect(.degrees(orbRotation))
                .shadow(color: activeColor.opacity(0.5), radius: 20, x: 0, y: 10)
            
            Image(systemName: ttsService.provider == .elevenLabs ? "waveform.circle.fill" : "applelogo")
                .font(.system(size: 50))
                .foregroundColor(.white)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                orbScale = 1.05
            }
            withAnimation(.linear(duration: 10.0).repeatForever(autoreverses: false)) {
                orbRotation = 360
            }
        }
    }
    
    private func sliderControl(title: String, value: Binding<Float>, range: ClosedRange<Float>, icon: String, maxIcon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                
                Slider(
                    value: value,
                    in: range,
                    onEditingChanged: { editing in
                        if editing {
                            lightImpact.impactOccurred()
                        } else {
                            mediumImpact.impactOccurred()
                        }
                    }
                )
                .tint(color)
                
                Image(systemName: maxIcon)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Logic & Computed Properties
    
    private var activeColor: Color {
        ttsService.provider == .elevenLabs ? .purple : .blue
    }
    
    private var providerDescription: String {
        if ttsService.provider == .elevenLabs {
            return "Adjusting stability and similarity boost for ElevenLabs."
        } else {
            return "Adjusting speech rate and pitch for Apple TTS."
        }
    }
    
    private var paceTitle: String {
        ttsService.provider == .elevenLabs ? "Similarity (Pace/Clarity)" : "Speech Rate"
    }
    
    private var expressivenessTitle: String {
        ttsService.provider == .elevenLabs ? "Stability (Expressiveness)" : "Pitch"
    }
    
    private var paceRange: ClosedRange<Float> {
        ttsService.provider == .elevenLabs ? 0.0...1.0 : 0.2...0.8
    }
    
    private var expressivenessRange: ClosedRange<Float> {
        ttsService.provider == .elevenLabs ? 0.0...1.0 : 0.5...2.0
    }
    
    private func triggerPreviewDebounced() {
        previewTask?.cancel()
        previewTask = Task {
            try? await Task.sleep(nanoseconds: 800_000_000) // 0.8s debounce
            guard !Task.isCancelled else { return }
            await MainActor.run {
                playPreview()
            }
        }
    }
    
    private func playPreview() {
        if isPlayingPreview {
            ttsService.stop()
            isPlayingPreview = false
            return
        }
        
        isPlayingPreview = true
        lightImpact.impactOccurred()
        
        Task {
            do {
                try await ttsService.speak(text: "Hi there! This is how my voice sounds with your new settings. I hope you like it.")
            } catch {
                print("Preview failed: \(error)")
            }
            await MainActor.run {
                isPlayingPreview = false
            }
        }
    }
}
