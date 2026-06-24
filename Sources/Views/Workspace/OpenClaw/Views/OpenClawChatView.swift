import SwiftUI

struct OpenClawChatView: View {
    @StateObject private var viewModel = OpenClawChatViewModel()

    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            ChatBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _ in
                    if let last = viewModel.messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }

            Divider()

            HStack {
                TextField("Message OpenClaw...", text: $viewModel.inputText)
                    .textFieldStyle(.roundedBorder)

                Button {
                    viewModel.send()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
                .disabled(viewModel.inputText.isEmpty || viewModel.isStreaming)
            }
            .padding()
        }
        .navigationTitle("AI Controller")
    }
}

struct ChatBubble: View {
    let message: OpenClawAgentMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            Text(message.text)
                .padding()
                .background(message.isUser ? Color.blue : Color.secondary.opacity(0.2))
                .foregroundStyle(message.isUser ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            if !message.isUser { Spacer() }
        }
    }
}
