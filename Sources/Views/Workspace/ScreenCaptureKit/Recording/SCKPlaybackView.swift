#if canImport(ScreenCaptureKit)

import SwiftUI
import AVKit

@available(iOS 27.0, *)
struct SCKPlaybackView: View {
    let session: SCKRecordingSession
    @State private var player: AVPlayer?
    @State private var currentTime: TimeInterval = 0
    @State private var showTranscript = true
    @State private var showOCR = false

    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            // Video Player Area
            ZStack {
                if let player = player {
                    VideoPlayer(player: player)
                        .frame(maxHeight: 300)
                } else {
                    Color.black
                        .frame(maxHeight: 300)
                        .overlay {
                            VStack(spacing: 12) {
                                Image(systemName: "video.slash.fill")
                                    .font(.largeTitle)
                                Text("Video Unavailable")
                            }
                            .foregroundStyle(.white)
                        }
                }

                // OCR Overlay (Simplified)
                if showOCR {
                    ForEach(currentOCRResults) { result in
                        Text(result.text)
                            .font(.system(size: 10))
                            .padding(2)
                            .background(Color.black.opacity(0.6))
                            .foregroundStyle(.white)
                            .position(x: result.boundingBox.midX * 300, y: (1 - result.boundingBox.midY) * 300)
                    }
                }
            }

            // Content Toggle
            Picker("View Mode", selection: $showTranscript) {
                Text("Transcript").tag(true)
                Text("AI Summary").tag(false)
            }
            .pickerStyle(.segmented)
            .padding()

            if showTranscript {
                transcriptList
            } else {
                summaryView
            }
        }
        .navigationTitle(session.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showOCR.toggle()
                } label: {
                    Image(systemName: showOCR ? "text.viewfinder" : "viewfinder")
                }
            }
        }
        .onAppear {
            if let url = session.videoURL {
                player = AVPlayer(url: url)
            }
        }
        .onReceive(timer) { _ in
            if let player = player {
                currentTime = player.currentTime().seconds
            }
        }
    }

    private var transcriptList: some View {
        ScrollViewReader { proxy in
            List(session.transcript) { segment in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(formatTime(segment.timestamp))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.blue)

                        if let speaker = segment.speaker {
                            Text(speaker)
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                        }
                    }

                    Text(segment.text)
                        .font(.body)
                        .foregroundStyle(isCurrentSegment(segment) ? .primary : .secondary)
                }
                .id(segment.id)
                .padding(.vertical, 4)
                .listRowBackground(isCurrentSegment(segment) ? Color.blue.opacity(0.1) : Color.clear)
            }
            .onChange(of: currentTime) { _ in
                if let current = session.transcript.last(where: { $0.timestamp <= currentTime }) {
                    withAnimation {
                        proxy.scrollTo(current.id, anchor: .center)
                    }
                }
            }
        }
    }

    private var summaryView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let summary = session.summary {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("AI Summary", systemImage: "sparkles")
                            .font(.headline)
                        Text(summary)
                            .font(.body)
                    }
                } else {
                    ContentUnavailableView("No Summary", systemImage: "sparkles", description: Text("AI summary hasn't been generated for this session."))
                }

                if let actionItems = session.actionItems, !actionItems.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Action Items", systemImage: "checklist")
                            .font(.headline)

                        ForEach(actionItems, id: \.self) { item in
                            HStack(alignment: .top) {
                                Image(systemName: "circle")
                                    .font(.caption)
                                    .padding(.top, 4)
                                Text(item)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }

    private var currentOCRResults: [SCKOCRResult] {
        session.ocrResults.filter { abs($0.timestamp - currentTime) < 1.0 }
    }

    private func isCurrentSegment(_ segment: SCKTranscriptSegment) -> Bool {
        guard let next = session.transcript.first(where: { $0.timestamp > segment.timestamp }) else {
            return currentTime >= segment.timestamp
        }
        return currentTime >= segment.timestamp && currentTime < next.timestamp
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let mins = Int(time) / 60
        let secs = Int(time) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

#endif
