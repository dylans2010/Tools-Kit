import SwiftUI

struct SpeechSetupView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var ttsService = TTSService.shared
    @State private var apiKey: String = ""
    @State private var hasCompletedSetup = false

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "waveform.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.accentColor)
                    .padding(.top, 40)

                Text("Welcome to AI Speech")
                    .font(.largeTitle)
                    .bold()

                Text("Choose your preferred text-to-speech provider to get started.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                VStack(spacing: 16) {
                    ForEach(TTSProvider.allCases) { provider in
                        Button(action: {
                            ttsService.provider = provider
                        }) {
                            HStack {
                                Image(systemName: provider.icon)
                                    .font(.title2)
                                VStack(alignment: .leading) {
                                    Text(provider.rawValue)
                                        .font(.headline)
                                    Text(description(for: provider))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if ttsService.provider == provider {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(ttsService.provider == provider ? Color.accentColor : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)

                if ttsService.provider == .elevenLabs {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ElevenLabs API Key")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        SecureField("Enter your API key", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.horizontal)
                }

                Spacer()

                Button(action: {
                    if ttsService.provider == .elevenLabs && !apiKey.isEmpty {
                        _ = SpeechKeychainManager.shared.saveKey(apiKey)
                    }
                    UserDefaults.standard.set(true, forKey: "speech_setup_completed")
                    dismiss()
                }) {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(15)
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }

    private func description(for provider: TTSProvider) -> String {
        switch provider {
        case .apple:
            return "Built-in, works offline, standard quality."
        case .elevenLabs:
            return "Highest quality AI voices, requires internet and API key."
        }
    }
}
