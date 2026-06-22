import SwiftUI

struct SpeechMainView: View {
    @StateObject private var sessionManager = SpeechSessionManager.shared
    @StateObject private var visionService = CloudVisionService.shared
    @State private var textInput: String = ""
    @State private var showTranscript = false
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        ZStack {
            if sessionManager.mode == .voice {
                VoiceModeFullScreen(sessionManager: sessionManager, showTranscript: $showTranscript)
                    .transition(.opacity)
            } else {
                ZStack {
                    VisionCameraOverlay(session: sessionManager.cameraManager.session)
                        .transition(.opacity)

                    VStack(spacing: 0) {
                        mainContent
                            .background(Color.clear)

                        inputArea
                    }
                }
            }
        }
        .navigationTitle(sessionManager.mode == .voice ? "" : "Vision Mode")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: SpeechSettingsView()) {
                    Image(systemName: "gear")
                }
            }

            ToolbarItem(placement: .navigationBarLeading) {
                Button("Reset") {
                    sessionManager.resetSession()
                }
            }
        }
        .sheet(isPresented: $showTranscript) {
            SpeechTranscriptView()
        }
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            Spacer()

            if sessionManager.isRecording {
                VStack(spacing: 12) {
                    AudioLevelIndicator(level: sessionManager.audioLevel)
                        .frame(height: 50)

                    Text(sessionManager.currentTranscription.isEmpty ? "Listening..." : sessionManager.currentTranscription)
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                }
                .padding()
            }
        }
    }

    private var inputArea: some View {
        HStack(spacing: 20) {
            Button(action: { setMode(.voice) }) {
                VStack {
                    Image(systemName: "mic.fill")
                        .font(.title2)
                    Text("Voice")
                        .font(.caption2)
                }
                .foregroundColor(sessionManager.mode == .voice ? .accentColor : .white)
            }

            Spacer()

            Button(action: {
                if sessionManager.isRecording {
                    sessionManager.stopRecording()
                } else {
                    try? sessionManager.startRecording()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(sessionManager.isRecording ? Color.red : Color.accentColor)
                        .frame(width: 64, height: 64)

                    Image(systemName: sessionManager.isRecording ? "stop.fill" : "mic.fill")
                        .font(.title)
                        .foregroundColor(.white)
                }
            }
            .shadow(radius: 4)

            Spacer()

            Button(action: { showTranscript = true }) {
                VStack {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.title2)
                    Text("Chat")
                        .font(.caption2)
                }
                .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 20)
        .background(.ultraThinMaterial)
    }

    private func setMode(_ mode: SpeechSessionMode) {
        withAnimation {
            sessionManager.mode = mode
        }
    }
}

// MARK: - Full-Screen Voice Mode

struct VoiceModeFullScreen: View {
    @ObservedObject var sessionManager: SpeechSessionManager
    @Binding var showTranscript: Bool

    @State private var dragOffset: CGSize = .zero
    @State private var isLongPressing = false
    @State private var showInterruptionUI = false
    @State private var activeFeature: SpeechInteractionFeature?
    @State private var intelligentModel = IntelligentSpeechModel()

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hue: 0.62, saturation: 0.35, brightness: 0.12),
                    Color(hue: 0.68, saturation: 0.45, brightness: 0.18),
                    Color(hue: 0.62, saturation: 0.35, brightness: 0.12)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar with mode switcher
                HStack {
                    Menu {
                        Button(action: { setMode(.voice) }) {
                            Label("Voice Mode", systemImage: "mic.fill")
                        }
                        Button(action: { setMode(.vision) }) {
                            Label("Vision Mode", systemImage: "eye.fill")
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "mic.fill")
                                .font(.caption)
                            Text("VOICE")
                                .font(.caption.bold())
                        }
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                    }

                    Spacer()

                    Button(action: { showTranscript = true }) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .foregroundColor(.white.opacity(0.7))
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }

                    Spacer().frame(width: 12)

                    // Status indicator
                    // Status indicator
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 8, height: 8)
                                .shadow(color: statusColor, radius: 4)

                            Text(sessionManager.speechState == .idle ? "READY" : sessionManager.speechState.statusText.uppercased())
                                .font(.caption2.bold())
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)

                        if let feature = activeFeature {
                            Text(feature.rawValue.replacingOccurrences(of: "_", with: " ").uppercased())
                                .font(.system(size: 8, weight: .black))
                                .foregroundColor(.accentColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                Spacer()

                // Central dynamic orb
            ZStack {
                DynamicOrbView(state: sessionManager.speechState, audioLevel: sessionManager.audioLevel)
                    .frame(width: 300, height: 300)

                if showInterruptionUI {
                    VStack {
                        Image(systemName: "waveform.and.mic")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                        Text("INTERRUPTING")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                    }
                    .padding(20)
                    .background(Color.red.opacity(0.6))
                    .clipShape(Circle())
                    .transition(.scale.combined(with: .opacity))
                }
            }

                Spacer()

                // Status text
                VStack(spacing: 8) {
                    Text(sessionManager.speechState.statusText)
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))

                    if sessionManager.isRecording && !sessionManager.currentTranscription.isEmpty {
                        Text(sessionManager.currentTranscription)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .lineLimit(3)
                    }
                }

                Spacer()
                    .frame(height: 40)

            // Main action button with advanced gestures
            ZStack {
                // Visual feedback for slide
                if dragOffset != .zero {
                    // Vertical feedback
                    VStack {
                        Image(systemName: "chevron.up.circle.fill")
                            .font(.title2)
                            .opacity(dragOffset.height < -100 ? 1 : (dragOffset.height < -30 ? 0.5 : 0.1))
                        Spacer()
                        Image(systemName: "chevron.down.circle.fill")
                            .font(.title2)
                            .opacity(dragOffset.height > 100 ? 1 : (dragOffset.height > 30 ? 0.5 : 0.1))
                    }
                    .frame(height: 180)

                    // Horizontal feedback
                    HStack {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.title2)
                            .opacity(dragOffset.width < -50 ? 1 : 0.1)
                        Spacer()
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.title2)
                            .opacity(dragOffset.width > 50 ? 1 : 0.1)
                    }
                    .frame(width: 180)
                }
                
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 80, height: 80)

                Circle()
                    .stroke(sessionManager.isRecording ? Color.red : statusColor, lineWidth: 3)
                    .frame(width: 80, height: 80)
                    .scaleEffect(isLongPressing ? 1.2 : 1.0)

                Image(systemName: actionButtonIcon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(sessionManager.isRecording ? .red : .white)
                }
            .overlay(
                // Intelligent Model connection
                Color.clear.onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
                    if sessionManager.isRecording {
                        intelligentModel.update(level: sessionManager.audioLevel) {
                            if !sessionManager.currentTranscription.isEmpty {
                                sessionManager.stopRecording()
                            }
                        }
                    } else {
                        intelligentModel.reset()
                    }
                }
            )
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        dragOffset = value.translation
                        if !isLongPressing {
                            isLongPressing = true
                            handlePressStart()
                        }

                        // Handle sliding parameters
                        if dragOffset.height < -100 {
                            activeFeature = .creativeMode
                        } else if dragOffset.height < -40 {
                            activeFeature = .detailedMode
                        } else if dragOffset.height > 100 {
                            activeFeature = .academicMode
                        } else if dragOffset.height > 40 {
                            activeFeature = .conciseMode
                        } else if dragOffset.width < -50 {
                            activeFeature = .discoveryMode
                        } else if dragOffset.width > 50 {
                            activeFeature = .translatorMode
                        } else {
                            activeFeature = nil
                        }
                    }
                    .onEnded { value in
                        handlePressEnd()

                        // Execute based on final drag position
                        if let feature = activeFeature {
                            try? sessionManager.startRecordingWithFeature(feature)
                        } else {
                            // Normal tap behavior if not a significant drag
                            if abs(dragOffset.height) < 10 && abs(dragOffset.width) < 10 {
                                handleTap()
                            }
                        }

                        withAnimation {
                            dragOffset = .zero
                            isLongPressing = false
                            showInterruptionUI = false
                        }
                    }
            )
                .padding(.bottom, 20)

                // Hint text
                Text(actionHintText)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.bottom, 30)
            }
        .onChange(of: sessionManager.audioLevel) { _, _ in }
        }
    }

    func handlePressStart() {
        if sessionManager.isSpeaking {
            withAnimation {
                showInterruptionUI = true
                activeFeature = .interruptionTrigger
            }
            TTSService.shared.stop()
            try? sessionManager.startRecordingWithFeature(.interruptionTrigger)
        }

        // Start 3s timer for extended listening
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if isLongPressing && abs(dragOffset.height) < 20 && abs(dragOffset.width) < 20 {
                activeFeature = .extendedListening
                // Haptic feedback could go here
            }
        }
    }

    private func handlePressEnd() {
        // Feature was already set or will be handled by onEnded
    }

    private func handleTap() {
        if sessionManager.isRecording {
            sessionManager.stopRecording()
        } else if sessionManager.isSpeaking {
            TTSService.shared.stop()
        } else {
            try? sessionManager.startRecording()
        }
        activeFeature = nil
    }

    private var statusColor: Color {
        switch sessionManager.speechState {
        case .idle: return .cyan
        case .listening: return .green
        case .processing: return .orange
        case .speaking: return .blue
        case .error: return .red
        }
    }

    private var statusIcon: String {
        switch sessionManager.speechState {
        case .idle: return "mic.fill"
        case .listening: return "waveform"
        case .processing: return "brain"
        case .speaking: return "speaker.wave.2.fill"
        case .error: return "exclamationmark.triangle"
        }
    }

    private var actionButtonIcon: String {
        if sessionManager.isRecording {
            return "stop.fill"
        } else if sessionManager.isSpeaking {
            return "speaker.slash.fill"
        } else {
            return "mic.fill"
        }
    }

    private var actionHintText: String {
        if sessionManager.isRecording {
            return "Tap to stop recording"
        } else if sessionManager.isSpeaking {
            return "Tap to stop speaking"
        } else if sessionManager.isProcessing {
            return "Processing your request..."
        } else {
            return "Tap the microphone to start"
        }
    }

    private func setMode(_ mode: SpeechSessionMode) {
        withAnimation {
            sessionManager.mode = mode
        }
    }
}


// MARK: - Waveform Bars for Voice Mode

// MARK: - Dynamic Orb View

struct DynamicOrbView: View {
    let state: SpeechState
    let audioLevel: Float

    @State private var rotation: Double = 0
    @State private var pulse: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Outer Gloom/Bloom
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [primaryColor.opacity(0.4), .clear]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
                .scaleEffect(pulse * (1.0 + CGFloat(audioLevel) * 0.2))

            // Rotating iridescence
            ZStack {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [primaryColor, secondaryColor, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 200, height: 200)
                        .offset(x: 20)
                        .rotationEffect(.degrees(Double(i) * 120 + rotation))
                        .opacity(0.3)
                        .blendMode(.screen)
                }
            }
            .blur(radius: 20)

            // Core
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [.white, primaryColor.opacity(0.8)]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 60
                    )
                )
                .frame(width: 100, height: 100)
                .shadow(color: primaryColor, radius: 20)
                .scaleEffect(state == .speaking ? 1.0 + CGFloat(audioLevel) * 0.5 : 1.0)

            // Detail Ring
            Circle()
                .stroke(primaryColor.opacity(0.5), lineWidth: 1)
                .frame(width: 220, height: 220)
                .scaleEffect(pulse)

            // State Icon (Subtle overlay)
            Image(systemName: statusIcon)
                .font(.system(size: 30, weight: .light))
                .foregroundColor(.white.opacity(0.6))
                .scaleEffect(pulse)
        }
        .onAppear {
            withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulse = 1.1
            }
        }
    }

    private var primaryColor: Color {
        switch state {
        case .idle: return .blue
        case .listening: return .cyan
        case .processing: return .indigo
        case .speaking: return .blue
        case .error: return .red
        }
    }

    private var secondaryColor: Color {
        switch state {
        case .idle: return .cyan
        case .listening: return .green
        case .processing: return .purple
        case .speaking: return .cyan
        case .error: return .orange
        }
    }

    private var statusIcon: String {
        switch state {
        case .idle: return "mic.fill"
        case .listening: return "waveform"
        case .processing: return "brain"
        case .speaking: return "speaker.wave.2.fill"
        case .error: return "exclamationmark.triangle"
        }
    }
}

struct WaveformBars: View {
    let level: Float
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<12, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(color.opacity(0.8))
                    .frame(
                        width: 4,
                        height: barHeight(for: index)
                    )
            }
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        let baseHeight: CGFloat = 4
        let maxAdditional: CGFloat = 32
        let normalizedLevel = CGFloat(level)

        // Create a wave pattern with the audio level
        let phase = Double(index) * 0.5
        let wave = sin(phase + Date().timeIntervalSince1970 * 3) * 0.5 + 0.5
        let audioInfluence = normalizedLevel * CGFloat(wave) * maxAdditional

        return baseHeight + audioInfluence
    }
}

// MARK: - Message Bubble

struct SpeechMessageBubble: View {
    let message: SpeechMessage

    var body: some View {
        Group {
            if message.isSpokenOnly {
                EmptyView()
            } else {
                HStack {
                    if message.role == .user { Spacer() }

                    VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                        if message.role == .system {
                            // System/error messages
                            Text(message.content)
                                .font(.caption)
                                .foregroundColor(.orange)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(12)
                        } else {
                            HStack(alignment: .bottom) {
                                if message.role == .assistant {
                                    Button(action: {
                                        Task {
                                            await SpeechSessionManager.shared.speak(text: message.content)
                                        }
                                    }) {
                                        Image(systemName: "speaker.wave.2.fill")
                                            .font(.caption)
                                            .foregroundColor(.accentColor)
                                    }
                                    .padding(.bottom, 10)
                                }

                                Text(message.content)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(message.role == .user ? Color.accentColor : Color(.systemGray5))
                                    .foregroundColor(message.role == .user ? .white : .primary)
                                    .cornerRadius(18)
                            }

                            Text(message.timestamp, style: .time)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }

                    if message.role == .assistant || message.role == .system { Spacer() }
                }
            }
        }
    }
}

// MARK: - Audio Level Indicator

struct AudioLevelIndicator: View {
    let level: Float

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<10, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.accentColor.opacity(Double(level) > Double(index) / 10.0 ? 1.0 : 0.2))
                    .frame(width: 6, height: 10 + (20 * CGFloat(sin(Double(index) * 0.5 + Date().timeIntervalSince1970 * 5))))
                    .transaction { $0.animation = nil }
            }
        }
    }
}

// MARK: - Intelligent Speech Model

struct IntelligentSpeechModel {
    private var silenceTimer: Timer?
    private let silenceThreshold: TimeInterval = 1.5

    mutating func update(level: Float, onSilence: @escaping () -> Void) {
        // If level is low, user might be done
        if level < 0.15 {
            if silenceTimer == nil {
                silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceThreshold, repeats: false) { _ in
                    onSilence()
                }
            }
        } else {
            silenceTimer?.invalidate()
            silenceTimer = nil
        }
    }

    mutating func reset() {
        silenceTimer?.invalidate()
        silenceTimer = nil
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var dotOffset: CGFloat = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 6, height: 6)
                    .offset(y: dotOffset)
                    .animation(
                        Animation.easeInOut(duration: 0.5)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: dotOffset
                    )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray5))
        .cornerRadius(15)
        .onAppear {
            dotOffset = -5
        }
    }
}
