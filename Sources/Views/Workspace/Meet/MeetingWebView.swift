import SwiftUI
import WebKit

struct MeetingWebView: View {
    @ObservedObject var controller: MeetSessionController

    var body: some View {
        VStack(spacing: 12) {
            Group {
                if let url = controller.webViewURL() {
                    InternalMeetingWebView(url: url)
                } else {
                    ContentUnavailableView(
                        "Session Unavailable",
                        systemImage: "video.slash",
                        description: Text("Meeting session is not ready yet.")
                    )
                }
            }
            .frame(height: 260)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            MeetingControlsView(
                isMuted: controller.isMicrophoneMuted,
                isCameraEnabled: controller.isCameraEnabled,
                isScreenSharing: controller.isScreenSharing,
                onToggleMute: { controller.toggleMute() },
                onToggleCamera: { controller.toggleCamera() },
                onToggleScreenShare: { controller.toggleScreenShare() },
                onLeaveMeeting: {
                    Task { await controller.leaveMeeting() }
                }
            )

            TabView {
                ParticipantsView(participants: controller.participants)
                    .tabItem { Label("Participants", systemImage: "person.3") }

                MeetingChatView(
                    threads: controller.chatThreads,
                    messages: controller.messages,
                    onAddThread: { controller.addThread(named: $0) },
                    onSendMessage: { text, threadID in
                        controller.sendMessage(text, threadId: threadID)
                    }
                )
                .tabItem { Label("Chat", systemImage: "message") }

                MeetingSettingsView(settings: $controller.settings)
                    .tabItem { Label("Settings", systemImage: "slider.horizontal.3") }

                MeetingSummaryView(summary: controller.summary)
                    .tabItem { Label("Summary", systemImage: "doc.text.magnifyingglass") }
            }
        }
        .navigationTitle("Meeting")
    }
}

private struct InternalMeetingWebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        return WKWebView(frame: .zero, configuration: configuration)
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if uiView.url != url {
            let request = URLRequest(url: url)
            uiView.load(request)
        }
    }
}
