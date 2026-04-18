import SwiftUI
import WebKit
import Daily

struct MeetingWebView: View {
    @ObservedObject var controller: MeetSessionController
    @State private var isChatSheetPresented = false
    @State private var isSettingsSheetPresented = false
    @State private var isSummarySheetPresented = false
    private let sheetDetents: Set<PresentationDetent> = [.medium, .large]

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

            ParticipantsView(participants: controller.participants)
                .frame(maxHeight: .infinity)
        }
        .navigationTitle("Meeting")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    isChatSheetPresented = true
                } label: {
                    Label("Chat", systemImage: "message")
                }

                Button {
                    isSettingsSheetPresented = true
                } label: {
                    Label("Settings", systemImage: "slider.horizontal.3")
                }

                Button {
                    isSummarySheetPresented = true
                } label: {
                    Label("Summary", systemImage: "doc.text.magnifyingglass")
                }
            }
        }
        .sheet(isPresented: $isChatSheetPresented) {
            NavigationStack {
                MeetingChatView(
                    threads: controller.chatThreads,
                    messages: controller.messages,
                    onAddThread: { controller.addThread(named: $0) },
                    onSendMessage: { text, threadID in
                        controller.sendMessage(text, threadId: threadID)
                    }
                )
            }
            .presentationDetents(sheetDetents)
        }
        .sheet(isPresented: $isSettingsSheetPresented) {
            NavigationStack {
                MeetingSettingsView(settings: $controller.settings)
            }
            .presentationDetents(sheetDetents)
        }
        .sheet(isPresented: $isSummarySheetPresented) {
            NavigationStack {
                MeetingSummaryView(summary: controller.summary)
            }
            .presentationDetents(sheetDetents)
        }
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
