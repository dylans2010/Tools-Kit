import SwiftUI
import AVFoundation

struct SpeechSettingsView: View {
    @ObservedObject var ttsService = TTSService.shared
    @StateObject var visionService = CloudVisionService.shared
    @State private var apiKey: String = ""
    @State private var visionApiKey: String = ""
    @State private var showSavedAlert = false
    @State private var savedAlertMessage = ""
    @State private var elevenLabsVoices: [ElevenLabsVoice] = []
    @State private var isLoadingVoices = false
    @State private var showLogs = false

    var body: some View {
        Form {
            // MARK: - AI Provider Warning
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("AI Provider Required")
                            .font(.subheadline.bold())
                        Text("Speech modes use the AI provider configured in the main app settings (AI Chat Settings). Make sure you have an AI provider and API key configured there first.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            // MARK: - TTS Provider
            Section(header: Text("TTS Provider")) {
                Picker("Provider", selection: $ttsService.provider) {
                    ForEach(TTSProvider.allCases) { provider in
                        Label(provider.rawValue, systemImage: provider.icon)
                            .tag(provider)
                    }
                }
                .pickerStyle(.inline)
            }

            // MARK: - Voice Customization
            Section {
                NavigationLink(destination: PersonalizedVoiceExperience()) {
                    HStack {
                        Image(systemName: "waveform")
                            .foregroundColor(.accentColor)
                        Text("Customize Voice")
                            .font(.headline)
                    }
                }
            }

            if ttsService.provider == .apple {
                Section(header: Text("Apple Voice Selection")) {
                    Picker("Voice", selection: $ttsService.selectedAppleVoiceID) {
                        Text("Default").tag(String?.none)
                        ForEach(AVSpeechSynthesisVoice.speechVoices(), id: \.identifier) { voice in
                            Text("\(voice.name) (\(voice.language))")
                                .tag(String?.some(voice.identifier))
                        }
                    }

                    Button(action: {
                        Task {
                            try? await ttsService.speakWithProvider(
                                text: "This is a sample of the selected Apple voice.",
                                provider: .apple,
                                voiceID: ttsService.selectedAppleVoiceID
                            )
                        }
                    }) {
                        Label("Play Sample", systemImage: "play.circle")
                    }
                }
            }

            // MARK: - ElevenLabs Configuration
            Section(
                header: Text("ElevenLabs Configuration"),
                footer: Text("API Key is stored securely in the Keychain. ElevenLabs provides high-quality AI voices for speech output.")
            ) {
                // API Key link
                Link(destination: URL(string: "https://elevenlabs.io/app/settings/api-keys")!) {
                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundColor(.accentColor)
                        Text("Get ElevenLabs API Key")
                            .foregroundColor(.accentColor)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                SecureField("API Key", text: $apiKey)

                Button("Save API Key") {
                    if SpeechKeychainManager.shared.saveKey(apiKey) {
                        savedAlertMessage = "Your ElevenLabs API key has been saved."
                        showSavedAlert = true
                        loadElevenLabsVoices()
                    }
                }
                .disabled(apiKey.isEmpty)

                if !elevenLabsVoices.isEmpty {
                    Picker("Voice", selection: $ttsService.selectedElevenLabsVoiceID) {
                        ForEach(elevenLabsVoices) { voice in
                            Text(voice.name).tag(String?.some(voice.voice_id))
                        }
                    }

                    Button(action: {
                        Task {
                            try? await ttsService.speakWithProvider(
                                text: "This is a sample of the selected Eleven Labs voice.",
                                provider: .elevenLabs,
                                voiceID: ttsService.selectedElevenLabsVoiceID
                            )
                        }
                    }) {
                        Label("Play Sample", systemImage: "play.circle")
                    }
                } else if isLoadingVoices {
                    HStack {
                        Text("Loading voices...")
                        Spacer()
                        ProgressView()
                    }
                }
            }

            // MARK: - Vision Configuration
            Section(
                header: Text("Vision Configuration"),
                footer: Text("Vision mode uses a separate API key to analyze camera frames. Choose OpenAI (GPT-4o) or Google Gemini.")
            ) {
                // API Key links for vision providers
                if visionService.selectedProvider == .openai {
                    Link(destination: URL(string: "https://platform.openai.com/api-keys")!) {
                        HStack {
                            Image(systemName: "key.fill")
                                .foregroundColor(.accentColor)
                            Text("Get OpenAI API Key")
                                .foregroundColor(.accentColor)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Link(destination: URL(string: "https://aistudio.google.com/apikey")!) {
                        HStack {
                            Image(systemName: "key.fill")
                                .foregroundColor(.accentColor)
                            Text("Get Google Gemini API Key")
                                .foregroundColor(.accentColor)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Picker("Vision Provider", selection: $visionService.selectedProvider) {
                    ForEach(VisionProvider.allCases) { provider in
                        Text(provider.rawValue).tag(provider)
                    }
                }
                .onChange(of: visionService.selectedProvider) { _ in
                    visionApiKey = visionService.getKey(for: visionService.selectedProvider) ?? ""
                    visionService.saveSettings()
                }

                SecureField("Vision API Key", text: $visionApiKey)

                Button("Save Vision API Key") {
                    if visionService.saveKey(visionApiKey, for: visionService.selectedProvider) {
                        savedAlertMessage = "Your \(visionService.selectedProvider.rawValue) API key has been saved."
                        showSavedAlert = true
                    }
                }
                .disabled(visionApiKey.isEmpty)
            }

            // MARK: - How It Works
            Section(header: Text("How It Works")) {
                VStack(alignment: .leading, spacing: 10) {
                    InfoRow(icon: "mic.fill", title: "Voice Mode", description: "Speak → AI responds → ElevenLabs reads the response aloud. Requires: AI provider (main settings) + ElevenLabs API key.")

                    InfoRow(icon: "keyboard", title: "Text Mode", description: "Type messages → AI responds in text. Requires: AI provider (main settings).")

                    InfoRow(icon: "eye.fill", title: "Vision Mode", description: "Camera captures frames → AI describes what it sees. Requires: Vision API key (OpenAI or Gemini).")
                }
                .padding(.vertical, 4)
            }

            // MARK: - Clear Keys
            Section {
                Button(role: .destructive, action: {
                    SpeechKeychainManager.shared.deleteKey()
                    apiKey = ""
                    elevenLabsVoices = []
                }) {
                    Text("Clear ElevenLabs API Key")
                }
            }
        }
        .navigationTitle("Speech Settings")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showLogs = true }) {
                    Image(systemName: "list.bullet.rectangle.portrait")
                }
            }
        }
        .sheet(isPresented: $showLogs) {
            NSpeechLoggerView()
        }
        .onAppear {
            apiKey = SpeechKeychainManager.shared.getKey() ?? ""
            visionApiKey = visionService.getKey(for: visionService.selectedProvider) ?? ""
            if !apiKey.isEmpty {
                loadElevenLabsVoices()
            }
        }
        .alert("Success", isPresented: $showSavedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(savedAlertMessage)
        }
    }

    private func loadElevenLabsVoices() {
        isLoadingVoices = true
        Task {
            do {
                elevenLabsVoices = try await ElevenLabsService.shared.getVoices()
            } catch {
                print("Failed to load voices: \(error)")
            }
            isLoadingVoices = false
        }
    }
}

// MARK: - Info Row Helper

private struct InfoRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
