import SwiftUI
import WebKit
import Daily

struct MeetingWebView: View {
    @ObservedObject var controller: MeetSessionController

    var body: some View {
        VStack(spacing: 12) {
            Group {
                if let url = controller.webViewURL() {
                    InternalMeetingWebView(
                        url: url,
                        onPageLoadStart: { controller.webViewDidStartLoadingPage() },
                        onPageLoadSuccess: { controller.webViewDidFinishLoadingPage() },
                        onJoinFailure: { controller.webViewDidFail($0) },
                        onCallEnded: { controller.webViewDidLeaveUnexpectedly() }
                    )
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
    let onPageLoadStart: () -> Void
    let onPageLoadSuccess: () -> Void
    let onJoinFailure: (String) -> Void
    let onCallEnded: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onPageLoadStart: onPageLoadStart,
            onPageLoadSuccess: onPageLoadSuccess,
            onJoinFailure: onJoinFailure,
            onCallEnded: onCallEnded
        )
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if uiView.url != url {
            let request = URLRequest(url: url)
            uiView.load(request)
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        private let onPageLoadStart: () -> Void
        private let onPageLoadSuccess: () -> Void
        private let onJoinFailure: (String) -> Void
        private let onCallEnded: () -> Void

        init(
            onPageLoadStart: @escaping () -> Void,
            onPageLoadSuccess: @escaping () -> Void,
            onJoinFailure: @escaping (String) -> Void,
            onCallEnded: @escaping () -> Void
        ) {
            self.onPageLoadStart = onPageLoadStart
            self.onPageLoadSuccess = onPageLoadSuccess
            self.onJoinFailure = onJoinFailure
            self.onCallEnded = onCallEnded
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            onPageLoadStart()
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            onPageLoadSuccess()
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            onJoinFailure(error.localizedDescription)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            onJoinFailure(error.localizedDescription)
        }

        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            onCallEnded()
        }
    }
}
