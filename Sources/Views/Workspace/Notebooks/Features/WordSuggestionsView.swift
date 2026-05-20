import SwiftUI

struct WordSuggestionsView: View {
    @Binding var isPresented: Bool
    var initialWord: String = ""
    var onInsert: ((String) -> Void)? = nil
    @StateObject private var vm = WordSuggestionsViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchField

                if vm.isLoading {
                    ProgressView().padding(.top, 40)
                    Spacer()
                } else if vm.synonyms.isEmpty && vm.simplerWords.isEmpty && vm.complexerWords.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            if let error = vm.errorMessage {
                                Text(error).foregroundColor(.red).padding()
                            }

                            suggestionSection(title: "Synonyms", icon: "arrow.left.arrow.right", words: vm.synonyms, color: .blue)
                            suggestionSection(title: "Simpler Alternatives", icon: "arrow.down.circle", words: vm.simplerWords, color: .green)
                            suggestionSection(title: "More Sophisticated", icon: "arrow.up.circle", words: vm.complexerWords, color: .purple)
                            suggestionSection(title: "Antonyms", icon: "arrow.uturn.left", words: vm.antonyms, color: .orange)
                            suggestionSection(title: "Rhymes", icon: "music.note", words: vm.rhymes, color: .pink)
                            suggestionSection(title: "Related Words", icon: "link", words: vm.related, color: .teal)

                            if !vm.inputWord.isEmpty && vm.synonyms.isEmpty && !vm.isLoading {
                                VStack(spacing: 12) {
                                    Image(systemName: "questionmark.circle").font(.largeTitle).foregroundColor(.secondary)
                                    Text("No suggestions found for '\(vm.inputWord)'.").foregroundColor(.secondary)
                                }
                                .padding(.top, 40)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Word Suggestions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { isPresented = false }
                }
            }
            .onAppear {
                if !initialWord.isEmpty {
                    Task { await vm.fetchSuggestions(for: initialWord) }
                }
            }
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("Word Suggestions", systemImage: "wand.and.stars")
        } description: {
            Text("Enter a word to discover synonyms, simpler alternatives, sophisticated variants, and more.")
        } actions: {
            VStack(spacing: 12) {
                Text("Popular lookups:").font(.caption).foregroundStyle(.secondary)
                HStack {
                    suggestionChip("Innovative")
                    suggestionChip("Effective")
                    suggestionChip("Challenge")
                }
            }
        }
    }

    private func suggestionChip(_ word: String) -> some View {
        Button(word) {
            vm.inputWord = word
            Task { await vm.fetchSuggestions(for: word) }
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "pencil").foregroundColor(.secondary)
            TextField("Enter a word...", text: $vm.inputWord)
                .textFieldStyle(.plain)
                .onSubmit {
                    Task { await vm.fetchSuggestions(for: vm.inputWord) }
                }
            if !vm.inputWord.isEmpty {
                Button { vm.inputWord = "" } label: { Image(systemName: "xmark.circle.fill").foregroundColor(.secondary) }
            }
        }
        .padding(10)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)
        .padding()
    }

    @ViewBuilder
    private func suggestionSection(title: String, icon: String, words: [String], color: Color) -> some View {
        if !words.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.1))
                            .frame(width: 32, height: 32)
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(color)
                    }
                    Text(title)
                        .font(.headline)
                }

                FlowLayout(words, spacing: 10) { word in
                    Button {
                        Task { await vm.fetchSuggestions(for: word) }
                    } label: {
                        Text(word)
                            .font(.system(size: 13, weight: .medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(color.opacity(0.1))
                            .foregroundColor(color)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(color.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            onInsert?(word)
                            isPresented = false
                        } label: {
                            Label("Insert into Page", systemImage: "plus.circle")
                        }

                        Button {
                            UIPasteboard.general.string = word
                        } label: {
                            Label("Copy Word", systemImage: "doc.on.doc")
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
        }
    }
}
