import SwiftUI

struct AIChatToolView: View {
    @StateObject private var viewModel = AIChatViewModel()

    var body: some View {
        VStack {
            if !viewModel.isApiKeySaved {
                apiKeySetupView
            } else {
                chatView
            }
        }
        .navigationTitle("AI Chat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.isApiKeySaved {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Settings", action: { viewModel.isApiKeySaved = false })
                        Button("Clear Chat", role: .destructive, action: viewModel.clearChat)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }

    private var apiKeySetupView: some View {
        VStack(spacing: 20) {
            Image(systemName: "key.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("OpenRouter API Key")
                .font(.title2)
                .bold()

            Text("Enter your API key to start chatting with AI models. Your key is stored securely in the Keychain.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            SecureField("sk-or-v1-...", text: $viewModel.apiKey)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            Button(action: viewModel.saveKey) {
                Text("Save and Continue")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .disabled(viewModel.apiKey.isEmpty)

            Link("Get an API key from OpenRouter", destination: URL(string: "https://openrouter.ai/keys")!)
                .font(.footnote)
        }
        .padding()
    }

    private var chatView: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            ChatBubble(message: message)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _ in
                    if let lastId = viewModel.messages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }

            if let error = viewModel.error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }

            HStack(spacing: 12) {
                TextField("Message", text: $viewModel.inputText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...5)

                Button(action: viewModel.sendMessage) {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.blue)
                    }
                }
                .disabled(viewModel.inputText.isEmpty || viewModel.isLoading)
            }
            .padding()
            .background(.ultraThinMaterial)
        }
    }
}

struct ChatBubble: View {
    let message: ChatMessage

    var isUser: Bool {
        message.role == "user"
    }

    var body: some View {
        HStack {
            if isUser { Spacer() }

            Text(message.content)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isUser ? Color.blue : Color(.secondarySystemBackground))
                .foregroundColor(isUser ? .white : .primary)
                .cornerRadius(18)
                .frame(maxWidth: 280, alignment: isUser ? .trailing : .leading)

            if !isUser { Spacer() }
        }
    }
}

struct AIChatTool: Tool {
    let name = "AI Chat"
    let icon = "bubble.left.and.bubble.right.fill"
    let category = ToolCategory.ai
    let complexity = ToolComplexity.advanced
    let description = "Advanced AI chatbot powered by OpenRouter"
    let requiresAPI = true

    var view: AnyView {
        AnyView(AIChatToolView())
    }
}
