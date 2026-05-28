import SwiftUI

struct SpeechHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var historyStore = SpeechHistoryStore.shared
    @State private var searchText = ""

    var onSelect: (SpeechRecording) -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(historyStore.search(query: searchText)) { recording in
                    Button {
                        onSelect(recording)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(recording.title)
                                .font(.headline)

                            HStack {
                                Text(recording.date.formatted(date: .abbreviated, time: .shortened))
                                Spacer()
                                Text(formatDuration(recording.duration))
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { indexSet in
                    let recordingsToDelete = indexSet.map { historyStore.recordings[$0] }
                    for recording in recordingsToDelete {
                        historyStore.deleteRecording(recording)
                    }
                }
            }
            .navigationTitle("Recording History")
            .searchable(text: $searchText, prompt: "Search Recordings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .overlay {
                if historyStore.recordings.isEmpty {
                    ContentUnavailableView("No Recordings", systemImage: "mic.slash", description: Text("Your saved recordings will appear here."))
                }
            }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
