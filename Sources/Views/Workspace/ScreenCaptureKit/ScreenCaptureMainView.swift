#if canImport(ScreenCaptureKit)

import SwiftUI


@available(iOS 27.0, *)
struct ScreenCaptureMainView: View {
    @State private var showingSettings = false
    @State private var recentSessions: [SCKRecordingSession] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection

                if !recentSessions.isEmpty {
                    recentRecordingsSection
                }

                SCKDashboardSection(title: "Recording & Capture") {
                    SCKDashboardCards.recordingAndCapture
                }

                SCKDashboardSection(title: "Professional & Study") {
                    SCKDashboardCards.professionalAndStudy
                }

                SCKDashboardSection(title: "Utilities & Insights") {
                    SCKDashboardCards.utilitiesAndInsights
                }
            }
            .padding()
        }
        .onAppear {
            recentSessions = Array(RecordingStorageManager.shared.loadSessions().prefix(5))
        }
        .navigationTitle("Screen Capture")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SCKSettingsView()
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Intelligent Capture")
                .font(.title2.bold())
            Text("Capture, transcribe, and analyze your screen with AI.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var recentRecordingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Recordings")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                NavigationLink(destination: SCKTimelineView()) {
                    Text("See All")
                        .font(.caption)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(recentSessions) { session in
                        NavigationLink(destination: SCKPlaybackView(session: session)) {
                            VStack(alignment: .leading, spacing: 8) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.blue.gradient)
                                        .frame(width: 160, height: 90)

                                    Image(systemName: "play.circle.fill")
                                        .font(.title)
                                        .foregroundStyle(.white)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(session.title)
                                        .font(.caption.bold())
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    Text(session.startTime.formatted(date: .abbreviated, time: .omitted))
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@available(iOS 27.0, *)
struct SCKDashboardSection<Content: View>: View {
    let title: String
    let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
                content()
            }
        }
    }
}

#Preview {
    NavigationStack {
        if #available(iOS 27.0, *) {
            ScreenCaptureMainView()
        } else {
            // Fallback on earlier versions
        }
    }
}


#endif
