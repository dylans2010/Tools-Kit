import SwiftUI
import AVFoundation

struct SpeechSettingsView: View {
    @ObservedObject var ttsService = TTSService.shared
    @State private var apiKey: String = ""
    @State private var showSavedAlert = false
    @State private var elevenLabsVoices: [ElevenLabsVoice] = []
    @State private var isLoadingVoices = false

    var body: some View {
        Form {
            Section(header: Text("TTS Provider")) {
                Picker("Provider", selection: $ttsService.provider) {
                    ForEach(TTSProvider.allCases) { provider in
                        Label(provider.rawValue, systemImage: provider.icon)
                            .tag(provider)
                    }
                }
                .pickerStyle(.inline)
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
                }
            }

            Section(header: Text("ElevenLabs Configuration"), footer: Text("API Key is stored securely in the Keychain.")) {
                SecureField("API Key", text: $apiKey)

                Button("Save API Key") {
                    if SpeechKeychainManager.shared.saveKey(apiKey) {
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
                } else if isLoadingVoices {
                    HStack {
                        Text("Loading voices...")
                        Spacer()
                        ProgressView()
                    }
                }
            }

            Section {
                Button(role: .destructive, action: {
                    SpeechKeychainManager.shared.deleteKey()
                    apiKey = ""
                    elevenLabsVoices = []
                }) {
                    Text("Clear API Key")
                }
            }
        }
        .navigationTitle("Speech Settings")
        .onAppear {
            apiKey = SpeechKeychainManager.shared.getKey() ?? ""
            if !apiKey.isEmpty {
                loadElevenLabsVoices()
            }
        }
        .alert("Success", isPresented: $showSavedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your ElevenLabs API key has been saved.")
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
