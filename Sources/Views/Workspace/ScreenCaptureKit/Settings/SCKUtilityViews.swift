#if canImport(ScreenCaptureKit)

import SwiftUI


@available(iOS 27.0, *)
struct SCKBugReporterView: View {
    @State private var description: String = ""

    var body: some View {
        Form {
            Section("Reproduction Details") {
                TextField("What happened?", text: $description, axis: .vertical)
                    .lineLimit(3...10)
            }

            Section("Attached Recording") {
                Button("Start Bug Recording") {
                    ScreenCaptureManager.shared.presentPicker()
                }
            }

            Section {
                Button("Submit Bug Report") {
                    // Logic to package recording and metadata
                }
                .disabled(description.isEmpty)
            }
        }
        .navigationTitle("Bug Reporter")
    }
}

@available(iOS 27.0, *)
struct SCKSearchView: View {
    @State private var query: String = ""
    @State private var recordings: [SCKRecordingSession] = []

    var filteredRecordings: [SCKRecordingSession] {
        if query.isEmpty { return recordings }
        return recordings.filter { session in
            session.title.localizedCaseInsensitiveContains(query) ||
            session.transcript.contains(where: { $0.text.localizedCaseInsensitiveContains(query) }) ||
            session.ocrResults.contains(where: { $0.text.localizedCaseInsensitiveContains(query) }) ||
            (session.summary?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    var body: some View {
        List(filteredRecordings) { session in
            NavigationLink(destination: SCKPlaybackView(session: session)) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.title)
                        .font(.headline)
                    Text(session.startTime.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !query.isEmpty {
                        if let match = findMatchSnippet(in: session) {
                            Text("... \(match) ...")
                                .font(.caption2)
                                .italic()
                                .foregroundStyle(.blue)
                                .lineLimit(2)
                        }
                    }
                }
            }
        }
        .searchable(text: $query, prompt: "Search titles, transcripts, or OCR")
        .navigationTitle("Search Recordings")
        .onAppear {
            recordings = RecordingStorageManager.shared.loadSessions()
        }
    }

    private func findMatchSnippet(in session: SCKRecordingSession) -> String? {
        if let transcriptMatch = session.transcript.first(where: { $0.text.localizedCaseInsensitiveContains(query) }) {
            return transcriptMatch.text
        }
        if let ocrMatch = session.ocrResults.first(where: { $0.text.localizedCaseInsensitiveContains(query) }) {
            return ocrMatch.text
        }
        return nil
    }
}

@available(iOS 27.0, *)
struct SCKTimelineView: View {
    @State private var sessions: [SCKRecordingSession] = []

    var body: some View {
        List {
            ForEach(groupedSessions.keys.sorted(by: >), id: \.self) { date in
                Section(header: Text(date.formatted(date: .complete, time: .omitted))) {
                    ForEach(groupedSessions[date] ?? []) { session in
                        NavigationLink(destination: SCKPlaybackView(session: session)) {
                            HStack(spacing: 16) {
                                Image(systemName: session.featureType.iconName)
                                    .font(.title2)
                                    .foregroundStyle(.blue)
                                    .frame(width: 40)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(session.title)
                                        .font(.headline)

                                    HStack {
                                        Text(session.startTime.formatted(date: .omitted, time: .shortened))
                                        Text("•")
                                        Text(formatDuration(session.duration))
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }

            if sessions.isEmpty {
                ContentUnavailableView("No Recordings", systemImage: "clock.arrow.circlepath", description: Text("Your recording history will appear here."))
            }
        }
        .navigationTitle("Timeline")
        .onAppear {
            sessions = RecordingStorageManager.shared.loadSessions()
        }
    }

    private var groupedSessions: [Date: [SCKRecordingSession]] {
        Dictionary(grouping: sessions) { session in
            Calendar.current.startOfDay(for: session.startTime)
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? ""
    }
}

@available(iOS 27.0, *)
struct SCKWorkspaceGeneratorView: View {
    @State private var sessions: [SCKRecordingSession] = []
    @State private var isGenerating = false
    @State private var generationStatus: String?

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("AI Workspace Automation")
                        .font(.headline)
                    Text("Turn your recordings into structured assets automatically. AI will scan for action items, meeting notes, and project drafts.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }

            Section("Select Session to Process") {
                if sessions.isEmpty {
                    Text("No recordings available")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sessions) { session in
                        Button {
                            generateAssets(for: session)
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(session.title)
                                        .foregroundStyle(.primary)
                                    Text(session.startTime.formatted())
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if session.summary != nil {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                    }
                }
            }

            if isGenerating {
                Section {
                    HStack {
                        ProgressView()
                            .padding(.trailing, 8)
                        Text(generationStatus ?? "Generating assets...")
                    }
                }
            }
        }
        .navigationTitle("Workspace Gen")
        .onAppear {
            sessions = RecordingStorageManager.shared.loadSessions()
        }
    }

    private func generateAssets(for session: SCKRecordingSession) {
        isGenerating = true
        generationStatus = "Analyzing content..."

        Task {
            do {
                try await SCKWorkspaceGenerator.shared.generateAssets(for: session)
                await MainActor.run {
                    isGenerating = false
                    generationStatus = nil
                    sessions = RecordingStorageManager.shared.loadSessions()
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    generationStatus = "Failed: \(error.localizedDescription)"
                }
            }
        }
    }
}


@available(iOS 27.0, *)
extension SCKFeatureType {
    var iconName: String {
        switch self {
        case .general: return "record.circle"
        case .aiCapture: return "sparkles.tv"
        case .meeting: return "video.badge.plus"
        case .presentation: return "rectangle.inset.filled.and.person.filled"
        case .study: return "book.closed.fill"
        case .tutorial: return "graduationcap.fill"
        case .bugReport: return "ladybug.fill"
        }
    }
}

@available(iOS 27.0, *)
struct SCKSettingsView: View {
    @State private var autoOCR = true
    @State private var autoTranscription = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Capture Settings") {
                    Toggle("Auto-OCR", isOn: $autoOCR)
                    Toggle("Auto-Transcription", isOn: $autoTranscription)
                }

                Section("Storage") {
                    Button("Clear All Recordings", role: .destructive) {
                        // Logic to clear storage
                    }
                }
            }
            .navigationTitle("SCK Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        // Dismiss
                    }
                }
            }
        }
    }
}


#endif
