import SwiftUI

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

struct SCKSearchView: View {
    @State private var query: String = ""

    var body: some View {
        List {
            // Search results from TimelineManager/RecordingStorageManager
        }
        .searchable(text: $query)
        .navigationTitle("Search Recordings")
    }
}

struct SCKTimelineView: View {
    var body: some View {
        List {
            // Timeline of recent captures
        }
        .navigationTitle("Timeline")
    }
}

struct SCKWorkspaceGeneratorView: View {
    var body: some View {
        VStack {
            ContentUnavailableView("Workspace Generator", systemImage: "square.stack.3d.up.fill", description: Text("Automatically generate Notes, Tasks, and more from your recordings."))
        }
        .navigationTitle("Workspace Generator")
    }
}

struct SCKAnalyticsView: View {
    var body: some View {
        VStack {
            Text("Recording Analytics")
                .font(.title)
            // Charts and metrics
        }
        .navigationTitle("Analytics")
    }
}

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
