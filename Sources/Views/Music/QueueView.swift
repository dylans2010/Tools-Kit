import SwiftUI

struct QueueView: View {
    @StateObject private var player = MusicPlayerManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showSleepTimer = false
    @State private var sleepMinutes: Double = 30

    var body: some View {
        NavigationStack {
            List {
                Section {
                    shuffleRepeatRow
                    sleepTimerRow
                }
                Section {
                    ForEach(Array(player.queue.enumerated()), id: \.element.id) { index, song in
                        HStack(spacing: 12) {
                            Group {
                                if index == player.currentIndex {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .foregroundColor(.accentColor)
                                } else {
                                    Text("\(index + 1)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(width: 20, alignment: .center)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(song.title)
                                    .font(.subheadline)
                                    .fontWeight(index == player.currentIndex ? .bold : .regular)
                                Text(song.artist)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if index == player.currentIndex {
                                Text("Playing")
                                    .font(.caption2)
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            guard index != player.currentIndex else { return }
                            player.play(song: song, queue: player.queue, startIndex: index)
                        }
                    }
                    .onMove { player.moveInQueue(from: $0, to: $1) }
                    .onDelete { player.removeFromQueue(at: $0) }
                } header: {
                    Text("Up Next")
                }
            }
            .navigationTitle("Queue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showSleepTimer) {
                sleepTimerSheet
            }
        }
    }

    private var shuffleRepeatRow: some View {
        HStack {
            Button {
                player.toggleShuffle()
            } label: {
                Label("Shuffle", systemImage: "shuffle")
                    .foregroundColor(player.shuffleEnabled ? .accentColor : .primary)
            }
            Spacer()
            Picker("Repeat", selection: Binding(
                get: { player.repeatMode },
                set: { player.setRepeatMode($0) }
            )) {
                Text("Off").tag(RepeatMode.off)
                Text("One").tag(RepeatMode.one)
                Text("All").tag(RepeatMode.all)
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 160)
        }
    }

    private var sleepTimerRow: some View {
        Button {
            showSleepTimer = true
        } label: {
            Label(
                player.sleepTimerEndDate != nil ? "Sleep Timer Active" : "Sleep Timer",
                systemImage: "timer"
            )
            .foregroundColor(player.sleepTimerEndDate != nil ? .accentColor : .primary)
        }
    }

    private var sleepTimerSheet: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper("Stop in \(Int(sleepMinutes)) min",
                            value: $sleepMinutes, in: 5...120, step: 5)
                } header: {
                    Text("Set Sleep Timer")
                }
                Section {
                    Button("Start Timer") {
                        player.setSleepTimer(minutes: Int(sleepMinutes))
                        showSleepTimer = false
                    }
                    if player.sleepTimerEndDate != nil {
                        Button("Cancel Timer", role: .destructive) {
                            player.setSleepTimer(minutes: 0)
                            showSleepTimer = false
                        }
                    }
                }
            }
            .navigationTitle("Sleep Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showSleepTimer = false }
                }
            }
        }
    }
}
